"""Arma los cursos grandes de MiniLang con frases de Tatoeba (tatoeba.org, CC BY 2.0 FR).

    python3 build_course.py <carpeta con los .tsv de Tatoeba> <carpeta de salida> [palabras]

Hace falta, de https://downloads.tatoeba.org/exports/per_language/:
  eng/eng_sentences.tsv, spa/spa_sentences.tsv y eng/eng-spa_links.tsv (descomprimidos).

Sale un paquete por sentido: en-es-10k.json (inglés para quien habla español) y
es-en-10k.json (español para quien habla inglés), con el formato de los paquetes
de MiniLang. El curso va por temas, como un curso de verdad:
  1. De A1 a B1, un programa en orden: saludos, por favor y gracias, presentarse,
     el verbo to be (y después sus negativas y preguntas), los números, la familia,
     el presente, el pasado, el futuro… Cada tema toma las frases que lo practican
     (la gramática se reconoce en la frase; el vocabulario, por las palabras de la
     frase en inglés) y, de ellas, las cortas y con palabras ya vistas o muy usadas.
  2. Después, hasta las 10.000 palabras, las palabras se enseñan de la más usada a
     la menos (contadas en todas las frases de Tatoeba, sin los nombres propios),
     cada una con una o dos frases que ya se entienden con ella. Dentro de cada
     nivel (B2, C1 y C2), esas frases se agrupan por tema (la gramática del nivel,
     viajes, salud, trabajo…) y cada tema da unidades de unas 45 frases.
  3. El nivel de A1 a B1 lo dice el programa; de B2 a C2, las palabras que se llevan.
"""
import json
import re
import zlib
import sys
from collections import Counter, defaultdict

TARGET_WORDS = int(sys.argv[3]) if len(sys.argv) > 3 else 10000
REV = 2                       # la versión del curso: la app cambia el instalado si este es más nuevo
PER_UNIT = 45                 # frases por unidad en la segunda parte
# El nivel (B2…C2) según las palabras que se llevan (aproximado, como los niveles del MCER).
LEVELS = [(600, 0), (1500, 1), (3000, 2), (5800, 3), (8200, 4), (10**9, 5)]
# Lo más raro que puede salir en cada nivel del programa (puesto de la palabra) y lo largo.
RANK_CAP = {0: 1500, 1: 3000, 2: 5500}
MAX_LEN = {0: 7, 1: 9, 2: 11}
# Las palabras nuevas que conviene que traiga cada frase del programa (A1 600, A2 1.500, B1 3.000).
NEW_PER = {0: 1, 1: 2, 2: 3}
# Lo largo que conviene que sea (en palabras).
GOOD_LEN = {0: 4, 1: 6, 2: 7}
BAD = re.compile(r'[0-9"/|()\[\]{}<>_#@*=+~^\\]')
# Frases que no van: tacos, y los temas que Tatoeba repite mucho por quién la escribe.
SKIP = re.compile(
    r"\b(shit|fuck\w*|ass|asshole|bitch|bastard|dick|cock|pussy|whore|slut|crap|piss|sexy|sex|sexual|porn\w*|nazi\w*"
    r"|mierda|joder|jodid\w*|puta|puto|putas|coño|cabrón|cabrones|gilipollas|culo|polla|follar|follamos|pene"
    r"|berber\w*|bereber\w*|kabyl\w*|cabil\w*|algeria\w*|argelia\w*|argelin\w*|algiers|argel|tamazight|tatoeba|esperanto|toki|pona"
    r"|ziri|skura|yanni|rima|mennad|baya|layla|sami|taninna|yidir|muiriel|mouloud|fadil|dania|salima)\b")
WORD = {
    "en": re.compile(r"[a-z]+(?:'[a-z]+)*"),
    "es": re.compile(r"[a-záéíóúüñ]+"),
}

# ---------------------------------------------------------------- los temas de vocabulario
# Se reconocen por las palabras de la frase en inglés (está en los dos cursos).
# clave: (título en español, título en inglés, icono, palabras)
THEMES = {
    "numbers": ("Los números", "Numbers", "🔢",
                "two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen "
                "seventeen eighteen nineteen twenty thirty forty fifty sixty seventy eighty ninety hundred "
                "thousand million first second third number numbers half dozen"),
    "colors": ("Los colores", "Colors", "🎨",
               "red blue green yellow black white brown pink purple gray grey color colors colour colours "
               "orange dark light"),
    "family": ("La familia", "Family", "👨‍👩‍👧",
               "mother father mom mum dad parents parent brother brothers sister sisters son sons daughter "
               "daughters wife husband family uncle aunt cousin cousins grandmother grandfather grandma grandpa "
               "grandparents baby children child kids nephew niece twins"),
    "time": ("Días, meses y la hora", "Days, months and time", "📅",
             "monday tuesday wednesday thursday friday saturday sunday today tomorrow yesterday week weeks "
             "weekend month months january february march april may june july august september october "
             "november december o'clock minute minutes hour hours clock birthday calendar morning evening "
             "afternoon night tonight noon midnight"),
    "food": ("Comida y bebida", "Food and drink", "🍎",
             "food eat eats ate eaten eating breakfast lunch dinner apple apples bread cheese meat fish "
             "chicken rice egg eggs milk water coffee tea juice wine beer cake sugar salt soup vegetables "
             "fruit banana bananas oranges potato potatoes tomato tomatoes pizza sandwich restaurant hungry "
             "thirsty cook cooked cooking delicious menu dessert butter chocolate meal drink drank drinking "
             "sweet salad"),
    "house": ("La casa", "The house", "🏠",
              "house home room kitchen bedroom bathroom door window table chair bed floor wall garden roof "
              "stairs sofa couch apartment furniture lamp shower closet desk rooms upstairs downstairs"),
    "clothes": ("La ropa", "Clothes", "👕",
                "shirt dress shoes hat coat jacket pants trousers skirt socks clothes wear wears wearing wore "
                "sweater tie gloves boots jeans suit uniform pocket"),
    "body": ("El cuerpo", "The body", "🖐️",
             "head hand hands eye eyes ear ears nose mouth teeth tooth hair arm arms leg legs foot feet face "
             "finger fingers neck shoulder knee lips skin"),
    "weather": ("El tiempo (clima)", "The weather", "☀️",
                "weather rain raining rained rainy snow snowing snowed sunny cloudy wind windy hot cold warm "
                "storm temperature umbrella cool degrees freezing"),
    "city": ("La ciudad", "The city", "🏙️",
             "city town street streets road corner station airport park bridge map museum church square "
             "building downtown neighborhood village traffic block address"),
    "shopping": ("De compras", "Shopping", "🛒",
                 "money buy buys bought buying sell sold price prices cost costs expensive cheap dollars dollar "
                 "euros pay paid shop shops store stores market cash supermarket"),
    "school": ("La escuela", "School", "🏫",
               "school teacher teachers student students class classes lesson lessons homework exam exams test "
               "study studied studying university college classroom library grade"),
    "work": ("El trabajo", "Work", "💼",
             "work works worked job jobs office boss company meeting salary career colleague colleagues "
             "employee employees manager business hire hired fired retire"),
    "travel": ("Viajes y transporte", "Travel and transport", "✈️",
               "travel traveled travelled trip train trains bus plane car cars taxi bicycle bike ticket tickets "
               "hotel vacation holiday passport luggage suitcase flight drive drove driving boat ship abroad "
               "tourist tourists journey"),
    "free": ("Tiempo libre y deportes", "Free time and sports", "⚽",
             "football soccer tennis baseball basketball game games sport sports swim swimming music piano "
             "guitar sing sang song songs dance dancing movie movies film films party hobby team"),
    "animals": ("Animales y naturaleza", "Animals and nature", "🐶",
                "dog dogs cat cats bird birds horse horses cow animal animals tree trees flower flowers river "
                "mountain mountains sea lake forest beach sky nature insects pet"),
    "feelings": ("Sentimientos", "Feelings", "😊",
                 "happy sad angry afraid scared tired worried nervous bored excited lonely upset feel feels "
                 "felt feeling feelings fear glad surprised disappointed jealous proud ashamed"),
    "health": ("La salud", "Health", "🩺",
               "sick ill doctor doctors hospital medicine pain hurt hurts headache fever cough healthy nurse "
               "dentist disease patient health cold flu injured"),
    "tech": ("Tecnología", "Technology", "💻",
             "computer computers phone internet email website online software laptop camera television tv "
             "battery password smartphone technology program printer"),
    "lang": ("Idiomas y comunicación", "Languages and communication", "💬",
             "language languages english spanish french german japanese chinese italian speak speaks spoke "
             "word words sentence sentences translate translation letter letters dictionary"),
    "relations": ("Amigos y pareja", "Friends and love", "💞",
                  "friend friends girlfriend boyfriend married marry marriage wedding divorce divorced date kiss "
                  "relationship love loves loved couple"),
    "politics": ("Sociedad y política", "Society and politics", "🗳️",
                 "government president law laws war country countries election vote politics political "
                 "society economy history king queen army nation citizens rights"),
    "crime": ("Ley y delitos", "Law and crime", "🚓",
              "police thief steal stole stolen crime prison jail judge court lawyer arrested murder guilty "
              "gun criminal"),
    "economy": ("Economía y negocios", "Economy and business", "📈",
                "economy business company companies bank market profit tax taxes industry trade investment "
                "price prices customers customer"),
    "media": ("Noticias y medios", "News and media", "📰",
              "newspaper newspapers news magazine article journalist radio report television"),
    "science": ("Ciencia", "Science", "🔬",
                "science scientist scientists research experiment planet earth energy theory chemistry physics "
                "mathematics math space moon universe"),
    "arts": ("Arte y cultura", "Arts and culture", "🎭",
             "art painting painter artist museum novel poem poetry theater theatre writer author culture "
             "book books concert"),
    "env": ("Medio ambiente", "The environment", "🌍",
            "pollution climate environment recycle waste plastic nature planet forests"),
    "character": ("Carácter y personalidad", "Character and personality", "🧠",
                  "kind honest smart clever stupid lazy brave shy polite rude friendly generous selfish "
                  "patient funny serious"),
}
THEME_WORDS = {k: set(v[3].split()) for k, v in THEMES.items()}

# ---------------------------------------------------------------- de qué trata cada palabra
# De B2 en adelante, las frases se agrupan por el campo de la palabra que enseñan, según
# WordNet (el «lexname» de su sentido más usado). Hace falta: pip install nltk y
# python -c "import nltk; nltk.download('wordnet')".
SENSES = [
    ("Personas y oficios", "People and jobs", "🧑‍🔧", "noun.person"),
    ("Familia, amigos y sociedad", "Family, friends and society", "🏛️", "noun.group verb.social noun.relation"),
    ("Lugares", "Places", "🗺️", "noun.location"),
    ("Objetos y cosas", "Objects and things", "🧰", "noun.artifact"),
    ("Comer y beber", "Eating and drinking", "🍽️", "noun.food verb.consumption"),
    ("El cuerpo y la salud", "Body and health", "🫀", "noun.body verb.body"),
    ("Animales", "Animals", "🐾", "noun.animal"),
    ("Plantas", "Plants", "🌿", "noun.plant"),
    ("Naturaleza y clima", "Nature and weather", "🌦️", "noun.phenomenon verb.weather noun.object"),
    ("Materiales y sustancias", "Materials and substances", "🧪", "noun.substance"),
    ("El tiempo y las fechas", "Time and dates", "⏰", "noun.time"),
    ("Cantidades y medidas", "Quantities and measures", "📏", "noun.quantity noun.shape"),
    ("Dinero y posesiones", "Money and possessions", "💰", "noun.possession verb.possession"),
    ("Sentimientos", "Feelings", "😊", "noun.feeling verb.emotion noun.motive"),
    ("Hablar y comunicar", "Talking and communicating", "💬", "noun.communication verb.communication"),
    ("Pensar y saber", "Thinking and knowing", "🧠", "noun.cognition verb.cognition"),
    ("Ver, oír y sentir", "Seeing, hearing and sensing", "👀", "verb.perception"),
    ("Moverse y viajar", "Moving and travelling", "🏃", "verb.motion"),
    ("Tocar y manejar", "Touching and handling", "✋", "verb.contact"),
    ("Hacer y crear", "Making and creating", "🛠️", "verb.creation"),
    ("Deporte y competición", "Sports and competition", "🏅", "verb.competition"),
    ("Cambios", "Change", "🔄", "verb.change"),
    ("Acciones y sucesos", "Actions and events", "🎬", "noun.act noun.event noun.process"),
    ("Estados y situaciones", "States and situations", "🌡️", "noun.state verb.stative"),
    ("Cómo es: cualidades", "Describing things", "🎨", "noun.attribute adj.all adj.pert adj.ppl"),
    ("Cómo, cuándo, cuánto", "How, when and how much", "🧭", "adv.all"),
]
SENSE_OF = {lex: i for i, (*_, lexes) in enumerate(SENSES) for lex in lexes.split()}
_SENSE_CACHE = {}


def word_sense(w):
    """El campo de una palabra inglesa (el de su sentido más usado), o None."""
    if w not in _SENSE_CACHE:
        from nltk.corpus import wordnet as wn
        syn = wn.synsets(w)
        _SENSE_CACHE[w] = SENSE_OF.get(syn[0].lexname()) if syn else None
    return _SENSE_CACHE[w]


def sense_group(english):
    """De qué trata una frase: el campo de su palabra inglesa más rara (la que se enseña)."""
    ws = sorted(set(tokens(english, "en")), key=lambda w: -EN_RANK.get(w, 10**6))
    for w in ws:
        if EN_RANK.get(w, 10**6) < 300:   # las de siempre (the, have, go…) no dicen de qué trata
            break
        g = word_sense(w)
        if g is not None:
            return g
    return None


# ---------------------------------------------------------------- la gramática de cada idioma
PP = ("been|seen|done|gone|eaten|made|taken|given|written|known|heard|lost|found|left|told|said|had|come|"
      "become|forgotten|bought|brought|thought|met|read|spoken|broken|chosen|won|got|gotten|kept|paid|sold|"
      "sent|spent|built|caught|taught|understood|forgiven|driven|ridden|stolen|worn|drunk|begun|sung|swum|"
      "fallen|felt|hidden|held|grown|thrown|flown|drawn|slept|run|put|cut|hit|set|let|shut|hurt")
PAST_IRR = ("went|saw|ate|had|took|came|made|got|gave|told|said|knew|thought|found|left|bought|brought|"
            "met|wrote|spoke|broke|ran|sat|stood|began|drank|drove|flew|forgot|heard|kept|lost|paid|sent|"
            "slept|spent|swam|taught|threw|understood|woke|wore|won|caught|chose|fell|felt|grew|hid|held|"
            "lent|meant|rode|rang|sang|sold|shook|stole|built|became|did")
ADJ_ED = ("tired|interested|worried|scared|married|excited|surprised|bored|pleased|used|supposed|related|"
          "retired|located|named|called|dressed|confused|embarrassed|disappointed|satisfied|prepared|"
          "allowed|amazed|annoyed|ashamed|born|frightened|exhausted|finished|engaged|involved|convinced|"
          "determined|qualified|crowded|closed|opened|tired|shocked|relaxed|concerned|impressed")
NOT_PAST = r"(?!(?:need|feed|speed|bleed|seed|indeed|red|bed|shed)\b)"
SUBJ = r"(?:i|you|we|they|he|she|it|tom|mary|my \w+|the \w+|our \w+|his \w+|her \w+)"

# Cada tema del programa: (nivel, clave, título en el idioma de quien aprende el curso, icono,
# expresión que lo reconoce, la que lo descarta, frases). Una clave «t:…» es un tema de
# vocabulario (THEMES). Los títulos van en el idioma que ya se habla.
G = "g"
CURRICULUM = {
    # Inglés para quien habla español: los títulos, en español.
    "en": [
        (0, G, "Saludos", "👋",
         r"\b(hello|hi|hey|good (morning|afternoon|evening|night)|goodbye|bye|how are you|how's it going|welcome)\b|^see you\b|\bsee you (later|soon|tomorrow|tonight|then|again|next)\b", None, 32),
        (0, G, "Por favor y gracias", "🙏",
         r"\b(thanks|thank you|sorry|excuse me|you're welcome|no problem)\b|^please\b|\bplease[.!?]$|, please\b", r"\b(as|if|what|where|whatever) (you|i|he|she|they|we) please\b", 32),
        (0, G, "Presentarse", "🙋",
         r"\b(my name|your name|his name|her name|i'm from|i am from|are you from|is from|nice to meet|how old)\b", None, 32),
        (0, G, "El verbo to be: I am, you are", "🧍",
         r"^(i am|i'm|you are|you're|he is|he's|she is|she's|it is|it's|we are|we're|they are|they're)\b",
         r"\b(not|n't)\b|\?|\b(am|is|are|'m|'re|'s) \w+ing\b|\bgoing\b", 40),
        (0, G, "To be: frases negativas", "🚫",
         r"\b(am not|'m not|isn't|is not|aren't|are not|'re not|'s not)\b", r"\b\w+ing\b|\?", 36),
        (0, G, "To be: preguntas", "❓",
         r"^(am|is|are|isn't|aren't) [a-z' ]+\?$", r"\b\w+ing\b", 36),
        (0, G, "This, that, these, those", "👉",
         r"^(this|that|these|those)\b|\b(this|that|these|those) (is|are|isn't|aren't)\b", r"\b\w+ing\b", 32),
        (0, "t:numbers", None, None, None, None, 32),
        (0, "t:colors", None, None, None, None, 28),
        (0, "t:family", None, None, None, None, 36),
        (0, G, "Have y has: tener", "🎒",
         rf"\b(i|you|we|they|he|she|tom|mary) (have|has|don't have|doesn't have)\b",
         rf"\b(have|has) (to|been|got|just|already|never|ever|{PP}|\w+ed)\b", 36),
        (0, G, "Posesivos: my, your, his, her", "🏷️",
         r"\b(my|your|his|her|our|their|mine|yours|ours|theirs)\b", None, 36),
        (0, "t:time", None, None, None, None, 36),
        (0, "t:food", None, None, None, None, 40),
        (0, "t:house", None, None, None, None, 32),
        (0, G, "Presente simple", "🔁",
         r"^(i|you|we|they) (?!am\b|are\b|have\b|was\b|were\b|will\b|can\b|could\b|would\b|should\b|must\b|might\b|do\b|don't\b|did\b|didn't\b|had\b|'m\b|'re\b|'ll\b|'d\b|'ve\b)[a-z]+\b"
         r"|^(he|she|tom|mary|it) (?!is\b|has\b|was\b|does\b|doesn't\b)[a-z]+s\b",
         rf"\b{NOT_PAST}\w+ed\b|\b({PAST_IRR}|was|were|wasn't|weren't|haven't|hasn't|will|won't)\b|'(ll|d|ve)\b|\b\w+ing\b|\?", 44),
        (0, G, "Do y does: negar y preguntar", "🤔",
         r"\b(don't|doesn't|do not|does not)\b|^(do|does) ", r"\bdid(n't)?\b", 40),
        (0, G, "Preguntas: what, where, who…", "🔎",
         r"^(what|where|who|when|why|how|which|whose)\b.*\?$", None, 40),
        (0, G, "Can: poder", "💪", r"\b(can|can't|cannot)\b", r"\b(the|a|this|that) can\b", 36),
        (0, G, "There is, there are", "📍",
         r"\bthere (is|are|isn't|aren't)\b|\bthere's\b|^(is|are) there\b", None, 32),
        (0, G, "Gustos: like, love, hate", "❤️",
         r"\b(like|likes|love|loves|hate|hates)\b",
         r"\b(would|'d|look|looks|looked|sound|sounds|feel|feels|seem|seems) like\b|\blike (a|an|this|that)\b", 36),
        (0, "t:clothes", None, None, None, None, 30),
        (0, "t:body", None, None, None, None, 30),
        (0, "t:weather", None, None, None, None, 30),
        # A2
        (1, G, "Presente continuo", "⏳",
         r"\b(am|is|are|'m|'re|'s|isn't|aren't) (not )?\w+ing\b",
         r"\bgoing to (?!(the|a|an|my|your|his|her|our|their|school|bed|work|church|class|college|town|jail|prison|boston|tom|mary)\b)\w+"
         r"|\b(is|are|'s) (something|anything|nothing|everything|morning|evening|ceiling|king|ring|thing|building|meeting|wedding|painting|interesting|amazing|boring|exciting|surprising|charming|annoying|disappointing|frightening|confusing|embarrassing|tiring|relaxing|missing)\b", 44),
        (1, "t:city", None, None, None, None, 36),
        (1, "t:shopping", None, None, None, None, 40),
        (1, G, "Pasado de to be: was, were", "🕰️",
         r"\b(was|were|wasn't|weren't)\b", rf"\b(was|were|wasn't|weren't) (being|\w+ing|\w+ed|{PP})\b", 40),
        (1, G, "Pasado simple", "⏮️",
         rf"^{SUBJ} (?:{NOT_PAST}\w{{2,}}ed|{PAST_IRR})\b", r"\?|\bdid\b", 48),
        (1, G, "Pasado: did y didn't", "❔", r"\b(did|didn't|did not)\b", None, 40),
        (1, "t:school", None, None, None, None, 40),
        (1, "t:work", None, None, None, None, 40),
        (1, G, "Futuro: going to", "🎯",
         r"\b(am|is|are|'m|'re|'s|isn't|aren't) (not )?going to (?!(the|a|an|my|your|his|her|our|their|school|bed|work|church|class|college|town|jail|prison|boston|tom|mary|chicago|australia|japan)\b)\w+", None, 40),
        (1, G, "Futuro: will", "🔮", r"\b(will|'ll|won't|will not)\b", r"\bif\b", 44),
        (1, G, "Comparativos", "⚖️", r"\b(\w+er|more \w+|less \w+|better|worse) than\b|\bas \w+ as\b", None, 40),
        (1, G, "Superlativos", "🏆",
         r"\bthe (most \w+|least \w+|\w+est|best|worst)\b",
         r"\bthe (rest|west|test|interest|forest|guest|contest|request|chest|nest|protest|east)\b", 36),
        (1, G, "Siempre, a veces, nunca", "🔄",
         r"\b(always|usually|often|sometimes|never|rarely|seldom|every day|once a|twice a)\b", None, 40),
        (1, G, "Must, have to, should", "⚠️",
         r"\b(must|mustn't|have to|has to|had to|should|shouldn't|need to|needs to)\b", r"\b(should|must) have\b", 44),
        (1, G, "Me, him, them: pronombres objeto", "👥", r"\b\w+ (me|him|us|them)\b", None, 36),
        (1, "t:travel", None, None, None, None, 44),
        (1, "t:free", None, None, None, None, 40),
        (1, "t:animals", None, None, None, None, 36),
        (1, "t:feelings", None, None, None, None, 40),
        # B1
        (2, G, "Presente perfecto", "✅",
         rf"\b(have|has|'ve|haven't|hasn't) (just |already |never |ever |not |)({PP}|\w+ed)\b",
         r"\b(have|has|'ve) been \w+ing\b|\b(should|must|might|could|would|may) have\b", 48),
        (2, G, "Pasado continuo", "🎞️", r"\b(was|were|wasn't|weren't) \w+ing\b", r"\bgoing to\b", 40),
        (2, G, "Primer condicional", "🔀",
         r"^if\b.*\b(will|'ll|won't)\b|\b(will|'ll|won't)\b.*\bif\b", None, 40),
        (2, G, "Segundo condicional", "💭",
         r"\bif\b.*\b(would|'d|could)\b|\b(would|'d|could)\b.*\bif\b", r"\b(would|could|'d) have\b|\bhad\b", 40),
        (2, G, "Would: pedir y desear", "🫖",
         r"\b(would like|'d like|would you|would rather|'d rather|would love|'d love)\b", r"\bif\b", 36),
        (2, G, "La voz pasiva", "🏗️",
         rf"\b(is|are|was|were|isn't|aren't|wasn't|weren't) ({PP}|\w+ed)\b",
         rf"\b(is|are|was|were|isn't|aren't|wasn't|weren't) ({ADJ_ED})\b|\b(is|are|was|were) (been|had|said)\b", 44),
        (2, G, "Who, which, that: relativos", "🔗",
         r"^(?!(who|which|whose|where|what)\b).*\b\w+ (who|which|whose) \w+", r"\?$", 40),
        (2, G, "Phrasal verbs", "🧩",
         r"\b(get|gets|got|look|looks|looked|give|gave|put|take|took|turn|turned|go|went|come|came|pick|picked|find|found|run|ran|set|bring|brought|break|broke|carry|fill|figure|hang|hold|keep|kept|let|shut|sit|stand|throw|wake|woke|grow|grew|calm|cheer|give|show|shows|showed) (up|out|off|on|down|back|over|away|around)\b", None, 44),
        (2, G, "Used to", "🧓", r"\bused to (?!(it|this|that|the|being|him|her|me|them)\b)\w+", r"\b(get|got|be|is|are|am|was|were|'m|'re|'s) used to\b", 32),
        (2, G, "Gerundio o infinitivo", "🔤",
         r"\b(enjoy|enjoys|enjoyed|stop|stopped|finish|finished|avoid|mind|keep|kept|started|start|began|prefer) \w+ing\b"
         r"|\b(want|wants|wanted|decide|decided|hope|hoped|plan|planned|try|tried|forgot|learn|learned|refuse|refused|promise|promised|expect|agreed) to \w+", None, 40),
        (2, G, "Might, may, could", "🎲", r"\b(might|may|could) (?!have\b)\w+", r"\bif\b", 40),
        (2, G, "Estilo indirecto", "🗣️",
         r"\b(said|told \w+|asked \w+) (that|if|whether|to)\b|\b(said|told me|told him|told her|told us|told them) (he|she|they|i|you|we|it)\b", None, 40),
        (2, "t:health", None, None, None, None, 40),
        (2, "t:tech", None, None, None, None, 40),
        (2, "t:lang", None, None, None, None, 40),
        (2, "t:relations", None, None, None, None, 40),
        # B2 y C1: la gramática del nivel en la segunda parte (agrupa las frases que la llevan).
        (3, G, "Presente perfecto continuo", "⌛", r"\b(have|has|'ve|haven't|hasn't) been \w+ing\b", None, 0),
        (3, G, "Pasado perfecto", "⏪",
         rf"\b(had|hadn't) (already |just |never |not |)({PP}|\w+ed)\b", r"\bhad (to|better)\b", 0),
        (3, G, "Tercer condicional", "🌀",
         r"\bif\b.*\b(would|could|might)(n't)? have\b|\b(would|could|might)(n't)? have\b.*\bif\b", None, 0),
        (3, G, "Should have, must have", "🧐",
         rf"\b(should|shouldn't|must|might|could|couldn't|would|wouldn't|may)( not)? have ({PP}|\w+ed)\b", None, 0),
        (3, G, "Wish e if only", "🌠", r"\b(wish|wishes|wished|if only)\b", None, 0),
        (3, G, "Pasiva avanzada", "🏛️",
         rf"\b(has been|have been|had been|will be|being|can be|must be|should be|could be) ({PP}|\w+ed)\b", None, 0),
        (4, G, "Conectores: although, however…", "🪢",
         r"\b(although|though|however|nevertheless|whereas|despite|in spite of|unless|even though|even if|therefore|otherwise|as long as|provided|in case|so that|in order to|meanwhile|moreover|furthermore)\b", None, 0),
        (4, G, "Expresiones hechas", "🗝️",
         r"\b(piece of cake|under the weather|once in a blue moon|the last straw|in hot water|call it a day|get out of hand|by the way|no wonder|it's up to you|make sense|makes sense|take it easy|never mind|big deal|on purpose|by heart|in the long run|after all|so far|as far as|in a hurry|out of the question|keep in mind|change your mind|make up your mind|take care|catch up|get along|look forward|give it a try|it's about time|for good)\b", None, 0),
        (4, G, "Inversión y énfasis", "🎯",
         r"^(never|rarely|seldom|hardly|not only|no sooner|under no circumstances|little did|only (then|when|after|if))\b|^(what i|what you|what he|what she|all i|all you) \w+ (is|was)\b", None, 0),
    ],
    # Español para quien habla inglés: los títulos, en inglés.
    "es": [
        (0, G, "Greetings", "👋",
         r"\b(hola|buen(os|as) (días|tardes|noches)|adiós|hasta (luego|mañana|pronto|la vista)|chao|chau|qué tal|cómo (estás|está|están)|bienvenid[oa]s?)\b", None, 32),
        (0, G, "Please and thank you", "🙏",
         r"\b(gracias|por favor|perdón|perdona|perdone|lo siento|disculp\w*|de nada)\b", None, 32),
        (0, G, "Introducing yourself", "🙋",
         r"\b(me llamo|te llamas|se llama|mi nombre|tu nombre|su nombre|de dónde|mucho gusto|encantad[oa]|cuántos años)\b|\b(soy|eres|es|somos|son) de (españa|méxico|francia|china|japón|alemania|inglaterra|italia|estados unidos|canadá|brasil|argentina|chile|colombia|perú|cuba|australia|rusia|aquí|allí|ahí)\b", None, 32),
        (0, G, "The verb ser: soy, eres, es", "🧍",
         r"\b(soy|eres|es|somos|sois|son)\b", r"\bno\b|¿|\?", 40),
        (0, G, "The verb estar: estoy, estás", "📍",
         r"\b(estoy|estás|está|estamos|estáis|están)\b", r"\b\w+(ando|iendo|yendo)\b|¿|\bno\b", 40),
        (0, G, "Saying no: negative sentences", "🚫",
         r"\bno (soy|eres|es|somos|son|estoy|estás|está|estamos|están|tengo|tiene|tienes|hay|sé|quiero|puedo|me|te|lo|la)\b", None, 36),
        (0, G, "Questions: qué, dónde, quién…", "🔎",
         r"^¿(qué|dónde|quién|quiénes|cuándo|por qué|cómo|cuál|cuáles|cuánto|cuánta|cuántos|cuántas|adónde|de dónde)\b", None, 40),
        (0, G, "Articles: el, la, un, una", "🔤",
         r"^(el|la|los|las|un|una|unos|unas) \w+ (es|está|son|están)\b", None, 36),
        (0, G, "This and that: este, ese", "👉",
         r"\b(este|esta|esto|estos|estas|ese|esa|eso|esos|esas|aquel|aquella|aquello)\b", None, 32),
        (0, "t:numbers", None, None, None, None, 32),
        (0, "t:colors", None, None, None, None, 28),
        (0, "t:family", None, None, None, None, 36),
        (0, G, "The verb tener", "🎒",
         r"\b(tengo|tienes|tiene|tenemos|tenéis|tienen)\b", r"\b(tengo|tienes|tiene|tenemos|tenéis|tienen) que\b", 36),
        (0, G, "Possessives: mi, tu, su", "🏷️",
         r"\b(mi|mis|tu|tus|su|sus|nuestro|nuestra|nuestros|nuestras)\b", None, 36),
        (0, "t:time", None, None, None, None, 36),
        (0, "t:food", None, None, None, None, 40),
        (0, "t:house", None, None, None, None, 32),
        (0, G, "Present tense: -ar verbs", "🔁",
         r"\b(habl|trabaj|estudi|compr|tom|cant|bail|mir|escuch|busc|necesit|viaj|cocin|llev|lleg|ayud|esper|lav|pas|camin|limpi|enseñ|pregunt|us|toc|gan|pag|dej|termin|llam)(o|as|a|amos|áis|an)\b", r"\?|¿|\bno\b", 40),
        (0, G, "Present tense: -er and -ir verbs", "🔂",
         r"\b(com|beb|le|aprend|viv|escrib|abr|corr|vend|comprend|cre|recib|sub|decid|asist|cog)(o|es|e|emos|éis|en|imos|ís)\b", r"\?|¿|\bno\b|\b(le|lee)\b", 40),
        (0, G, "Gustar: what you like", "❤️",
         r"\b(me|te|le|nos|os|les) (gusta|gustan|encanta|encantan|interesa|interesan)\b", None, 36),
        (0, G, "Hay: there is, there are", "📦", r"\bhay\b", r"\bhay que\b", 32),
        (0, G, "Querer and poder", "💪",
         r"\b(quiero|quieres|quiere|queremos|quieren|puedo|puedes|puede|podemos|pueden)\b", None, 40),
        (0, G, "The verb ir: voy, vas, va", "🚶",
         r"\b(voy|vas|va|vamos|van) (a|al)\b", r"\b(voy|vas|va|vamos|van) a \w+(ar|er|ir)\b", 32),
        (0, "t:clothes", None, None, None, None, 30),
        (0, "t:body", None, None, None, None, 30),
        (0, "t:weather", None, None, None, None, 30),
        # A2
        (1, G, "Present progressive: estoy hablando", "⏳",
         r"\b(estoy|estás|está|estamos|están) \w+(ando|iendo|yendo)\b", None, 44),
        (1, G, "Reflexive verbs: me levanto", "🪥",
         r"\b(me|te|se|nos) (levanto|levantas|levanta|levantamos|levantan|acuesto|acuestas|acuesta|ducho|duchas|ducha|lavo|lava|lavas|visto|vistes|viste|despierto|despiertas|despierta|siento|sientes|siente|quedo|quedas|queda|quedamos|quedan|preocupo|preocupa|preocupes|casó|casaron|olvidé|olvidó|acuerdo|acuerdas|acuerda|enojé|enfadé|equivoqué|equivocas|equivoca|llamo|llamas|llama)\b", None, 36),
        (1, "t:city", None, None, None, None, 36),
        (1, "t:shopping", None, None, None, None, 40),
        (1, G, "Past tense: the preterite", "⏮️",
         r"\b(\w{2,}(ó|aste|aron|ieron|iste|ió)|\w+(é)|fui|fue|fuiste|fuimos|fueron|tuve|tuvo|tuvieron|hice|hizo|hicieron|dije|dijo|dijeron|vi|vio|vino|vine|estuve|estuvo|pude|pudo|puse|puso|supe|supo|quise|quiso|di|dio|traje|trajo)\b",
         r"\b\w+(aré|eré|iré)\b|\b(qué|porqué|café|bebé|también|josé|esté|dé|sé|fé|puré|rené|quizá|está|así)\b(?!.*\b\w{2,}(ó|aste|aron|ieron|iste|ió)\b)|\?|¿", 48),
        (1, G, "Past: the imperfect", "🕰️",
         r"\b(\w+(aba|abas|ábamos|aban)|\w+(ía|ías|íamos|ían)|era|eras|éramos|eran|iba|ibas|íbamos|iban)\b",
         r"\b\w+ría\b|\b(día|días|tía|tías|policía|todavía|compañía|alegría|energía|economía|geografía|biología|mía|mías|sandía|lejanía|guía|fotografía|frutería|mayoría)\b(?!.*\b(\w+aba|era|iba|\w+ía)\b)", 44),
        (1, "t:school", None, None, None, None, 40),
        (1, "t:work", None, None, None, None, 40),
        (1, G, "Going to: voy a + verb", "🎯",
         r"\b(voy|vas|va|vamos|van) a \w+(ar|er|ir)(lo|la|le|los|las|me|te|se|nos)?\b", None, 40),
        (1, G, "The future: hablaré", "🔮",
         r"\b(\w+(ar|er|ir)|tendr|podr|sabr|habr|har|dir|saldr|vendr|pondr|querr|cabr|valdr)(é|ás|á|emos|án)\b", r"\bsi\b", 44),
        (1, G, "Comparisons: más que, tan como", "⚖️",
         r"\b(más|menos) \w+ (que|de)\b|\btan \w+ como\b|\b(mejor|peor|mayor|menor)(es)? que\b", None, 40),
        (1, G, "Superlatives: el más alto", "🏆",
         r"\b(el|la|los|las) (más|menos) \w+\b|\b\w+ísim[oa]s?\b", None, 36),
        (1, G, "Always, sometimes, never", "🔄",
         r"\b(siempre|nunca|jamás|a veces|a menudo|normalmente|todos los días|cada día|de vez en cuando|casi nunca)\b", None, 40),
        (1, G, "Tener que and deber", "⚠️",
         r"\b(tengo|tienes|tiene|tenemos|tienen|tenía|tuve|tuvo) que\b|\bhay que\b|\b(debo|debes|debe|debemos|deben)\b", None, 44),
        (1, G, "Object pronouns: lo, la, le", "👥",
         r"\b(lo|la|los|las|le|les|me|te|nos) (vi|vio|veo|ves|ve|conozco|conoce|conoces|quiero|quiere|dije|dijo|di|dio|doy|da|llamo|llamé|llamó|tengo|tiene|necesito|necesita|compré|compró|hice|hizo|sé|sabe|creo|encontré|encontró|traje|ayudo|ayudé|ayudó|puse|espero|esperé|busco|busqué|mandé|envié|pregunté|preguntó|olvidé|perdí|leí|escribí)\b", None, 36),
        (1, "t:travel", None, None, None, None, 44),
        (1, "t:free", None, None, None, None, 40),
        (1, "t:animals", None, None, None, None, 36),
        (1, "t:feelings", None, None, None, None, 40),
        # B1
        (2, G, "Present perfect: he hablado", "✅",
         r"\b(he|has|ha|hemos|habéis|han) (\w+(ado|ido)|hecho|dicho|visto|escrito|puesto|vuelto|roto|muerto|abierto|cubierto|descubierto|resuelto)\b", None, 48),
        (2, G, "Conditional: hablaría", "💭",
         r"\b\w+(ría|rías|ríamos|rían)\b",
         r"\b(todavía|alegría|categoría|energía|mayoría|librería|panadería|carnicería|frutería|ferretería|galería|batería|lotería|teoría|cafetería|joyería|peluquería|zapatería)\b", 44),
        (2, G, "Hopes and wishes: ojalá, espero que", "🌠",
         r"\b(ojalá|espero que|quiero que|quiere que|para que|antes de que|es (importante|necesario|posible|mejor|probable) que|no creo que|dudo que)\b", None, 40),
        (2, G, "Commands: ¡ven!, dime", "📣",
         r"^¡?(ven|dime|haz|ten|pon|sal|ve|mira|escucha|espera|abre|cierra|siéntate|cállate|dame|déjame|ayúdame|llámame|vamos|no (hagas|digas|vayas|te preocupes|toques|comas|llores|grites|corras|mires|olvides))\b", None, 40),
        (2, G, "Impersonal se", "🪧",
         r"^(aquí )?se (habla|hablan|vende|venden|dice|puede|necesita|prohíbe|busca|alquila|come|bebe|sabe|cree|cerró|abrió|rompió|construyó|escribe|usa)\b", None, 32),
        (2, G, "Relative clauses: que, quien, donde", "🔗",
         r"^(?!(que|quien|donde)\b).*\b\w+ (que|quien|quienes|donde|cuyo|cuya|lo que) \w+", r"\?|¿", 40),
        (2, G, "Por and para", "↔️", r"\bpor\b.*\bpara\b|\bpara\b.*\bpor\b", r"\bpor (favor|qué)\b", 36),
        (2, G, "Past perfect: había hablado", "⏪",
         r"\b(había|habías|habíamos|habían) (\w+(ado|ido)|hecho|dicho|visto|escrito|puesto|vuelto|roto|muerto|abierto)\b", None, 40),
        (2, "t:health", None, None, None, None, 40),
        (2, "t:tech", None, None, None, None, 40),
        (2, "t:lang", None, None, None, None, 40),
        (2, "t:relations", None, None, None, None, 40),
        # B2 y C1 (en la segunda parte)
        (3, G, "Imperfect subjunctive: si tuviera", "🌀",
         r"\b\w+(áramos|iéramos|ieran|ieras|iera|iese|iesen|aran|aras)\b|\b(tuviera|hubiera|fuera|pudiera|quisiera|dijera|hiciera|estuviera|supiera)\b",
         r"\b(cualquiera|quienquiera|afuera|fuera de|madera|primera|tercera|bandera|carrera|cartera|frontera|escalera|manera|tijera|primavera|enfermera|camarera|compañera|soltera|entera|sincera|extranjera|ingeniera|carnicera|cocinera|panadera)\b", 0),
        (3, G, "If clauses: si tuviera, haría", "🔀",
         r"^si\b.*\b\w+(ría|rías|ríamos|rían)\b|\b\w+(ría|rían)\b.*\bsi\b", None, 0),
        (3, G, "Would have: habría hecho", "🧐",
         r"\b(habría|habrías|habríamos|habrían|hubiera|hubieras|hubiéramos|hubieran) (\w+(ado|ido)|hecho|dicho|visto|escrito|puesto|vuelto)\b", None, 0),
        (3, G, "The passive: fue construido", "🏛️",
         r"\b(es|son|fue|fueron|será|serán|ha sido|han sido|había sido) (\w+(ado|ada|ados|adas|ido|ida|idos|idas)|hecho|hecha|escrito|escrita|descubierto|construido|construida)\b", None, 0),
        (4, G, "Linking words: aunque, sin embargo", "🪢",
         r"\b(aunque|sin embargo|no obstante|a pesar de|mientras que|a menos que|en cambio|por lo tanto|por eso|así que|de modo que|con tal de que|en cuanto|puesto que|ya que|dado que|además)\b", None, 0),
        (4, G, "Common expressions", "🗝️",
         r"\b(tomar el pelo|meter la pata|echo de menos|echa de menos|echar de menos|da igual|vale la pena|valer la pena|tengo ganas|tiene ganas|tienes ganas|darse cuenta|me di cuenta|se dio cuenta|hace falta|tienes razón|tiene razón|tengo prisa|tener miedo|tengo miedo|a lo mejor|de repente|por fin|sin duda|en serio|de hecho|cuanto antes|poco a poco|al fin y al cabo)\b", None, 0),
    ],
}
# El resto de frases de la segunda parte que no cae en ningún tema: lo que más se nota.
FALLBACK = {
    "en": [("Más frases: preguntas", "❓", r"\?$"), ("Más frases: en pasado", "⏮️", rf"\b(was|were|did|didn't|{PAST_IRR}|{NOT_PAST}\w{{3,}}ed)\b"),
           ("Más frases: el futuro", "🔮", r"\b(will|'ll|won't|going to)\b"), ("Más frases: negativas", "🚫", r"\b(not|n't|never|no)\b"),
           ("Más frases", "📘", r".")],
    "es": [("More sentences: questions", "❓", r"\?$"), ("More sentences: the past", "⏮️", r"\b(\w{2,}(ó|aste|aron|ieron|iste|ió|aba|aban|ía|ían)|fue|fui|era|eran)\b"),
           ("More sentences: the future", "🔮", r"\b\w+(ré|rás|rá|remos|rán)\b|\b(voy|vas|va|vamos|van) a \w+r\b"),
           ("More sentences: negatives", "🚫", r"\b(no|nunca|nadie|nada|tampoco)\b"), ("More sentences", "📘", r".")],
}


def load(folder):
    global ALL_EN, ALL_ES, EN_RANK

    def sentences(path):
        out = {}
        with open(path, encoding="utf-8") as f:
            for line in f:
                parts = line.rstrip("\n").split("\t")
                if len(parts) == 3:
                    out[parts[0]] = parts[2].strip()
        return out

    en = sentences(f"{folder}/eng_sentences.tsv")
    es = sentences(f"{folder}/spa_sentences.tsv")
    ALL_EN, ALL_ES = list(en.values()), list(es.values())
    freq = Counter()
    for t in ALL_EN:
        freq.update(tokens(t, "en"))
    EN_RANK = {w: i for i, (w, _) in enumerate(freq.most_common())}
    pairs = []
    with open(f"{folder}/eng-spa_links.tsv", encoding="utf-8") as f:
        for line in f:
            a, b = line.split()
            if a in en and b in es:
                pairs.append((en[a], es[b]))
    return pairs


def usable(s, lang):
    n = len(s.split())
    return 1 <= n <= (13 if lang == "en" else 14) and not BAD.search(s) and len(s) <= 90


SHORT_OK = {"en": {"a", "i"}, "es": {"a", "y", "o", "e", "u"}}


def tokens(s, lang):
    out = []
    for w in WORD[lang].findall(s.lower().replace("’", "'")):
        if w.endswith("'s"):
            w = w[:-2]
        if len(w) >= 2 or w in SHORT_OK[lang]:
            out.append(w)
    return out


def proper_names(pairs, target):
    """Los nombres: palabras con mayúscula que quedan igual en la traducción (Tom, Boston)."""
    cap, same = Counter(), Counter()
    for t, s in pairs:
        src = set(re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+", s))
        for w in re.findall(r"[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+", t):
            if w[0].isupper() and w != "I":
                cap[w.lower()] += 1
                if w in src:
                    same[w.lower()] += 1
    return {w for w in cap if same[w] / cap[w] >= 0.6}


def norm(s):
    return s.lower().replace("’", "'").strip()


def theme_of(english):
    """El tema de vocabulario de una frase (por su inglés): el que más palabras suyas lleva."""
    ws = set(tokens(english, "en"))
    best, hits = None, 0
    for k, words in THEME_WORDS.items():
        n = len(ws & words)
        if n > hits:
            best, hits = k, n
    return best


def build(pairs, target, source):
    # Las frases del idioma que se aprende, con sus traducciones (y las otras formas que valen).
    tr = defaultdict(list)       # frase → traducciones
    back = defaultdict(list)     # traducción → frases (otras formas de decirlo)
    seen = {}
    for en, es in pairs:
        t, s = (en, es) if target == "en" else (es, en)
        if not usable(t, target) or not usable(s, source):
            continue
        key = t.lower()
        if key in seen:
            t = seen[key]
        else:
            seen[key] = t
        if s not in tr[t]:
            tr[t].append(s)
        if t not in back[s]:
            back[s].append(t)
    sents = list(tr)
    oriented = [(en, es) if target == "en" else (es, en) for en, es in pairs]
    names = proper_names(oriented, target)
    # Lo que se usa cada palabra: en todas las frases del idioma (millones en inglés).
    freq = Counter()
    for t in ALL_EN if target == "en" else ALL_ES:
        freq.update(w for w in tokens(t, target) if w not in names)
    vocab = {}
    for t in sents:
        if SKIP.search(t.lower()) or any(SKIP.search(s.lower()) for s in tr[t]):
            continue
        ws = {w for w in tokens(t, target) if w not in names}
        if ws and all(w in freq for w in ws):
            vocab[t] = ws
    used_words = set().union(*vocab.values())
    freq = Counter({w: c for w, c in freq.items() if w in used_words})
    rank = {w: i for i, (w, _) in enumerate(sorted(freq.items(), key=lambda kv: (-kv[1], kv[0])))}
    top = {t: max(rank[w] for w in ws) for t, ws in vocab.items()}
    english = {t: (t if target == "en" else tr[t][0]) for t in vocab}
    themes = {t: theme_of(english[t]) for t in vocab}
    src_title = 0 if source == "es" else 1

    def topic(entry):
        level, kind, title, icon, rx, ex, n = entry
        if kind.startswith("t:"):
            k = kind[2:]
            es_t, en_t, ic, _ = THEMES[k]
            return level, (es_t, en_t)[src_title], ic, ("t", k, None), n
        return level, title, icon, ("g", re.compile(rx), re.compile(ex) if ex else None), n

    def matches(m, t):
        if m[0] == "t":
            return themes[t] == m[1]
        low = norm(t)
        return bool(m[1].search(low)) and not (m[2] and m[2].search(low))

    def what(m, t):
        """Lo que hace que la frase sea del tema («hello», «good morning», «mother»…), para variar."""
        if m[0] == "t":
            return next((w for w in tokens(english[t], "en") if w in THEME_WORDS[m[1]]), "")
        x = m[1].search(norm(t))
        return x.group(0) if x else ""

    topics = [topic(e) for e in CURRICULUM[target]]
    used, known = set(), set()
    units = []   # (nivel, título, icono, [frases])

    # ---- 1. El programa de A1 a B1: cada tema con sus frases, en orden.
    for level, title, icon, m, n in topics:
        if n == 0:
            continue
        cap, longest, ideal, good = RANK_CAP[level], MAX_LEN[level], NEW_PER[level], GOOD_LEN[level]
        cands = [t for t in vocab if t not in used and top[t] < cap and 2 <= len(t.split()) <= longest and matches(m, t)]
        if len(cands) < n:   # pocos: se admiten frases un poco más largas o raras
            cands = [t for t in vocab if t not in used and top[t] < cap * 2 and len(t.split()) <= longest + 3 and matches(m, t)]
        # Primero las cortas con palabras muy usadas; luego, una a una, las que traen las palabras
        # nuevas justas (una en A1, dos en A2, tres en B1), y de las más usadas.
        pool, picked, signs, uses = set(cands), [], set(), Counter()
        key_of = {t: what(m, t) for t in cands}
        # En A1, mejor sin nombres raros (Meruert, Oyajisan…): Tom y Mary sí, que salen siempre.
        named = {t: level == 0 and any(w in names and w not in ("tom", "mary") for w in tokens(t, target)) for t in cands}
        while pool and len(picked) < n:
            # Las palabras nuevas justas, sin repetir mucho lo mismo («hey», «hey», «hey»…),
            # de las más usadas y cortas. El desempate, fijo pero sin ir por orden alfabético.
            best = min(pool, key=lambda t: (abs(len(vocab[t] - known) - ideal) + uses[key_of[t]] // 3 + named[t], top[t] // 300,
                                            abs(len(t.split()) - good), zlib.crc32(t.encode())))
            pool.remove(best)
            sign = tuple(sorted(vocab[best]))
            if sign in signs:   # la misma frase con otra puntuación o en otro orden
                continue
            signs.add(sign)
            uses[key_of[best]] += 1
            picked.append(best)
            used.add(best)
            known |= vocab[best]
        if len(picked) >= 6:
            units.append((level, title, icon, picked))
        print(f"  {target} {['A1','A2','B1','B2','C1','C2'][level]} {title}: {len(picked)} frases ({len(cands)} posibles)")
    phase1 = len(known)

    # ---- 2. Hasta las 10.000 palabras, de la más usada a la menos.
    by_rank = defaultdict(list)
    for t in vocab:
        if t not in used:
            by_rank[top[t]].append(t)

    def score(t):
        n = len(t.split())
        return (0 if 3 <= n <= 9 else 1, abs(n - 6), len(tr[t]) * -1, t)

    words_by_rank = sorted(rank, key=rank.get)
    rest = []   # (frase, palabras llevadas tras ella)
    for r in range(len(rank)):
        if words_by_rank[r] in known:
            continue
        cands = sorted(by_rank.get(r, []), key=score)
        if not cands:
            continue
        for t in cands[:2]:
            used.add(t)
            known |= vocab[t]
            rest.append((t, len(known)))
        if len(known) >= TARGET_WORDS:
            break
    # Por niveles (según las palabras que se llevan) y, dentro de cada uno, por temas.
    first = max(lv for lv, *_ in units) + 1
    gram = [(lv, title, icon, m) for lv, title, icon, m, n in topics if m[0] == "g"]
    fallback = [(title, icon, re.compile(rx)) for title, icon, rx in FALLBACK[target]]
    bands = defaultdict(list)
    for t, total in rest:
        level = max(first, next(s for lim, s in LEVELS if total <= lim))
        bands[level].append(t)
    for level in sorted(bands):
        groups = defaultdict(list)
        order = []
        for t in bands[level]:
            low = norm(t)
            # La gramática del nivel (o de los dos de antes), luego de qué trata la palabra que
            # enseña (su campo en WordNet) y, si no se sabe, lo que más se nota de la frase.
            key = next((("g", i) for i, (lv, _, _, m) in enumerate(gram)
                        if level - 2 <= lv <= level and lv >= 3 and m[1].search(low) and not (m[2] and m[2].search(low))), None)
            if key is None:
                key = ("w", sense_group(english[t]))
            if key[1] is None:
                key = ("f", next(i for i, (_, _, rx) in enumerate(fallback) if rx.search(low)))
            groups[key].append(t)
        order = ([k for k in (("g", i) for i in range(len(gram))) if k in groups]
                 + [k for k in (("w", i) for i in range(len(SENSES))) if k in groups]
                 + [k for k in (("f", i) for i in range(len(fallback))) if k in groups])
        small = []
        for k in order:
            items = groups[k]
            if len(items) < 12:
                small += items
                continue
            if k[0] == "g":
                title, icon = gram[k[1]][1], gram[k[1]][2]
            elif k[0] == "w":
                title, icon = SENSES[k[1]][src_title], SENSES[k[1]][2]
            else:
                title, icon = fallback[k[1]][0], fallback[k[1]][1]
            chunks = [items[i:i + PER_UNIT] for i in range(0, len(items), PER_UNIT)]
            if len(chunks) > 1 and len(chunks[-1]) < 15:
                last = chunks.pop()
                chunks[-1] += last
            for i, c in enumerate(chunks):
                units.append((level, title + (f" ({i + 1})" if len(chunks) > 1 else ""), icon, c))
        if small:
            title, icon = fallback[-1][0], fallback[-1][1]
            if units and units[-1][1].startswith(title) and units[-1][0] == level:
                units[-1][3].extend(small)
            else:
                units.append((level, title, icon, small))

    # ---- Las palabras nuevas de cada unidad, en el orden final.
    out_units, seen_words = [], set()
    for level, title, icon, ts in units:
        new = []
        items_json = []
        for t in ts:
            for w in sorted(vocab[t] - seen_words, key=rank.get):
                seen_words.add(w)
                new.append(w)
            ss = tr[t]
            others = [x for s in ss[:1] for x in back[s] if x != t][:3]
            src = "/".join(dict.fromkeys(x.replace("/", " ") for x in ss[:3]))
            tgt = "/".join(dict.fromkeys([t] + others))
            items_json.append([src, tgt])
        out_units.append(
            {
                "section": level,
                "title": title,
                "icon": icon,
                "lessons": max(2, min(8, (len(ts) + 6) // 7)),
                "words": new,
                "items": items_json,
            }
        )
    print(f"  {target}: {phase1} palabras en el programa (A1–B1), {len(seen_words)} en total")
    return out_units, len(seen_words), sum(len(u["items"]) for u in out_units)


def write(units, target, source, path, words):
    names = {
        ("en", "es"): ("Inglés · 10.000 palabras", "🇬🇧"),
        ("es", "en"): ("Spanish · 10,000 words", "🇪🇸"),
    }
    name, flag = names[(target, source)]
    head = {
        "minilang": 1,
        "id": f"{target}-{source}-10k",
        "rev": REV,
        "target": target,
        "source": source,
        "name": name,
        "flag": flag,
        "full": True,
        "words": words,
        "credit": "Tatoeba (tatoeba.org), CC BY 2.0 FR",
    }
    with open(path, "w", encoding="utf-8") as f:
        f.write(json.dumps(head, ensure_ascii=False)[:-1] + ',"units":[\n')
        f.write(",\n".join(json.dumps(u, ensure_ascii=False) for u in units))
        f.write("\n]}\n")


def main():
    pairs = load(sys.argv[1])
    out = sys.argv[2]
    for target, source in (("en", "es"), ("es", "en")):
        units, words, sentences = build(pairs, target, source)
        path = f"{out}/{target}-{source}-10k.json"
        write(units, target, source, path, words)
        levels = Counter(u["section"] for u in units)
        print(f"{path}: {words} palabras, {sentences} frases, {len(units)} unidades, niveles {dict(sorted(levels.items()))}")


if __name__ == "__main__":
    main()
