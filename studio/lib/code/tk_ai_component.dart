/// Componente «Asistente IA» de las aplicaciones generadas: Claude con el SDK
/// oficial de Anthropic para Python (`pip install anthropic`). La clave llega
/// por la variable de entorno ANTHROPIC_API_KEY (al ejecutar desde el
/// estudio, la de Ajustes → Inteligencia artificial); nunca va en el código.
const tkAiAssistantPython = r'''

# ---------------------------------------------------------- asistente IA
class AiError(Exception):
    """Fallo de la IA, con un mensaje para el usuario."""


class AiAssistant:
    """Claude desde el código: ask (una pregunta), chat (una conversación),
    summarize, translate, classify y extract (datos en JSON). Las variantes
    *_async no congelan la ventana y llaman a los eventos done(result) o
    error(error). La clave se lee de ANTHROPIC_API_KEY."""

    # Modelos con reintento en otro modelo si sus filtros rechazan la petición.
    _FALLBACK_MODELS = {"claude-fable-5-1", "claude-opus-5-5", "claude-opus-5", "claude-sonnet-5-5"}

    def __init__(self, owner, model="claude-opus-5-5", system="", effort="medium",
                 max_tokens=16000, done=None, error=None, web=False):
        self._owner = owner
        self.model = model
        self.system = system
        self.effort = effort
        self.max_tokens = int(max_tokens)
        self.done = done
        self.error = error
        self._web = web
        self.history = []
        self._client = None
        self._fallbacks = model in self._FALLBACK_MODELS
        self._pending = None

    # ------------------------------------------------------------ cliente
    def _api(self):
        if self._client is None:
            try:
                import anthropic
            except ImportError:
                raise AiError(
                    "Falta el SDK de Anthropic. Instálelo con: python3 -m pip install anthropic"
                ) from None
            self._anthropic = anthropic
            self._client = anthropic.Anthropic()
        return self._client

    def _create(self, messages, output_format=None, system=None):
        client = self._api()
        anthropic = self._anthropic
        params = {
            "model": self.model,
            "max_tokens": self.max_tokens,
            "messages": messages,
            "output_config": {"effort": self.effort},
        }
        if output_format is not None:
            params["output_config"]["format"] = output_format
        system = self.system if system is None else system
        if system:
            params["system"] = system
        try:
            if self._fallbacks:
                try:
                    response = client.beta.messages.create(
                        betas=["server-side-fallback-2026-07-01"],
                        fallbacks="default",
                        **params,
                    )
                except (TypeError, anthropic.BadRequestError) as e:
                    # Un SDK o una cuenta sin fallbacks: sin ellos.
                    if "fallback" not in str(e).lower():
                        raise
                    self._fallbacks = False
                    response = client.messages.create(**params)
            else:
                response = client.messages.create(**params)
        except anthropic.AuthenticationError:
            raise AiError("La clave de Anthropic no es válida (ANTHROPIC_API_KEY).") from None
        except anthropic.RateLimitError:
            raise AiError("Demasiadas peticiones a Claude: espere un momento y repita.") from None
        except anthropic.APIConnectionError:
            raise AiError("No se pudo conectar con Claude: compruebe la conexión.") from None
        except anthropic.APIStatusError as e:
            raise AiError("Error de Claude (%s): %s" % (e.status_code, e.message)) from None
        if response.stop_reason == "refusal":
            raise AiError("Claude ha rechazado esta petición por sus filtros de seguridad.")
        return response

    @staticmethod
    def _text(response):
        return "".join(b.text for b in response.content if b.type == "text").strip()

    @staticmethod
    def _content(prompt, image=None):
        if image is None:
            return prompt
        import base64
        import mimetypes
        kind = mimetypes.guess_type(image)[0] or "image/png"
        with open(image, "rb") as f:
            data = base64.standard_b64encode(f.read()).decode("utf-8")
        return [
            {"type": "image", "source": {"type": "base64", "media_type": kind, "data": data}},
            {"type": "text", "text": prompt},
        ]

    # ------------------------------------------------------------- llamadas
    def ask(self, prompt, image=None):
        """Una pregunta suelta (sin historial). image: ruta de una imagen."""
        return self._text(self._create([{"role": "user", "content": self._content(prompt, image)}]))

    def chat(self, message, image=None):
        """Un mensaje de una conversación que recuerda lo anterior."""
        self.history.append({"role": "user", "content": self._content(message, image)})
        try:
            response = self._create(self.history)
        except Exception:
            self.history.pop()
            raise
        # La respuesta entera vuelve al historial (también su razonamiento).
        self.history.append({"role": "assistant", "content": response.content})
        return self._text(response)

    def reset(self):
        """Empieza una conversación nueva."""
        self.history = []

    def summarize(self, text, words=100):
        return self.ask(
            "Resume el texto siguiente en unas %d palabras, en su mismo idioma. "
            "Responde solo con el resumen.\n\n%s" % (int(words), text)
        )

    def translate(self, text, language="English"):
        return self.ask(
            "Traduce el texto siguiente a %s. Responde solo con la traducción.\n\n%s" % (language, text)
        )

    def classify(self, text, labels):
        """Una de las etiquetas de labels."""
        labels = [str(x) for x in labels]
        response = self._create(
            [{"role": "user", "content": "Clasifica el texto en una de las categorías dadas.\n\n" + str(text)}],
            output_format={
                "type": "json_schema",
                "schema": {
                    "type": "object",
                    "properties": {"label": {"type": "string", "enum": labels}},
                    "required": ["label"],
                    "additionalProperties": False,
                },
            },
        )
        import json
        return json.loads(self._text(response))["label"]

    def extract(self, text, fields):
        """Un diccionario con fields (lista de nombres, o {nombre: descripción})."""
        if not isinstance(fields, dict):
            fields = {str(f): "" for f in fields}
        response = self._create(
            [{"role": "user", "content": "Extrae del texto los campos pedidos. Si un dato no aparece, "
                                         "deja una cadena vacía.\n\n" + str(text)}],
            output_format={
                "type": "json_schema",
                "schema": {
                    "type": "object",
                    "properties": {
                        name: ({"type": "string", "description": desc} if desc else {"type": "string"})
                        for name, desc in fields.items()
                    },
                    "required": list(fields),
                    "additionalProperties": False,
                },
            },
        )
        import json
        return json.loads(self._text(response))

    # ---------------------------------------------------- en segundo plano
    def _background(self, call, *args, **kwargs):
        """Ejecuta call en un hilo y avisa en la ventana (done / error)."""
        if self._web:
            # En una página, la petición ya espera a la respuesta.
            try:
                result = call(*args, **kwargs)
            except Exception as e:
                if self.error:
                    return self.error(e)
                raise
            if self.done:
                self.done(result)
            return result
        import queue
        import threading
        results = queue.Queue()

        def job():
            try:
                results.put((True, call(*args, **kwargs)))
            except Exception as e:
                results.put((False, e))

        def poll():
            try:
                ok, value = results.get_nowait()
            except queue.Empty:
                self._owner.after(80, poll)
                return
            self._pending = None
            if ok:
                if self.done:
                    self.done(value)
            elif self.error:
                self.error(value)
            else:
                print("Error de la IA:", value)

        threading.Thread(target=job, daemon=True).start()
        self._pending = True
        self._owner.after(80, poll)

    @property
    def busy(self):
        return self._pending is not None

    def ask_async(self, prompt, image=None):
        return self._background(self.ask, prompt, image)

    def chat_async(self, message, image=None):
        return self._background(self.chat, message, image)

    def summarize_async(self, text, words=100):
        return self._background(self.summarize, text, words)

    def translate_async(self, text, language="English"):
        return self._background(self.translate, text, language)

    def classify_async(self, text, labels):
        return self._background(self.classify, text, labels)

    def extract_async(self, text, fields):
        return self._background(self.extract, text, fields)
''';
