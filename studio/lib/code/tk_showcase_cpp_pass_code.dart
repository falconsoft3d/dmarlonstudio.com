part of 'tk_examples.dart';

// El código en C++ de DMarlonPass (tk_showcase_cpp_pass.dart): va tal cual en
// Form1.cpp, después de los textos (namespace tx).
const _passIncludes = r'''#include <algorithm>
#include <cctype>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>
#include <FL/Fl_Box.H>
#include <FL/Fl_Button.H>
#include <FL/Fl_Check_Button.H>
#include <FL/Fl_Choice.H>
#include <FL/Fl_Double_Window.H>
#include <FL/Fl_Image_Surface.H>
#include <FL/Fl_Input.H>
#include <FL/Fl_Menu_Item.H>
#include <FL/Fl_Multiline_Input.H>
#include <FL/Fl_Output.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_Value_Slider.H>
#include <FL/filename.H>
#include <FL/fl_ask.H>
#include <FL/fl_draw.H>
#include <FL/fl_utf8.h>
#ifndef _WIN32
#include <sys/stat.h>
#endif
''';

const _passCode = r'''
// ============================================================ la criptografía
// Todo lo que pide el formato de KeePass (KDBX), sin bibliotecas: SHA-256,
// SHA-512, HMAC, AES-256, ChaCha20, Salsa20, BLAKE2b y Argon2. Cada pieza se
// comprueba con los vectores de prueba oficiales en selftest().
namespace kp {

// ---- texto, archivos y la carpeta de ajustes
std::string fmt(std::string s, std::initializer_list<std::string> args) {
  int i = 0;
  for (const auto& a : args) {
    std::string key = "{" + std::to_string(i++) + "}";
    for (size_t p = s.find(key); p != std::string::npos; p = s.find(key, p + a.size())) s.replace(p, key.size(), a);
  }
  return s;
}
std::string lower(std::string s) {
  for (auto& c : s) c = (char)std::tolower((unsigned char)c);
  return s;
}
std::string trim(const std::string& s) {
  size_t a = s.find_first_not_of(" \t\r\n");
  if (a == std::string::npos) return "";
  size_t b = s.find_last_not_of(" \t\r\n");
  return s.substr(a, b - a + 1);
}
std::vector<std::string> split(const std::string& s, char sep) {
  std::vector<std::string> out;
  size_t a = 0;
  while (true) {
    size_t b = s.find(sep, a);
    out.push_back(s.substr(a, b == std::string::npos ? std::string::npos : b - a));
    if (b == std::string::npos) break;
    a = b + 1;
  }
  return out;
}
double now_s() {
  using namespace std::chrono;
  return duration_cast<duration<double>>(steady_clock::now().time_since_epoch()).count();
}
std::string config_dir() {
  if (const char* o = fl_getenv("DMS_PASS_DIR")) return o;
#ifdef _WIN32
  const char* a = fl_getenv("APPDATA");
  return std::string(a ? a : ".") + "\\DMarlon Studio Demos\\dmarlonpass";
#elif defined(__APPLE__)
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/Library/Application Support/DMarlon Studio Demos/dmarlonpass";
#else
  const char* h = fl_getenv("HOME");
  return std::string(h ? h : ".") + "/.config/DMarlon Studio Demos/dmarlonpass";
#endif
}
bool read_file(const std::string& path, std::string& out) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  out.clear();
  char buf[65536];
  size_t n;
  while ((n = std::fread(buf, 1, sizeof buf, f)) > 0) out.append(buf, n);
  std::fclose(f);
  return true;
}
// Se escribe aparte y luego se cambia el nombre: un corte a medias no deja el archivo roto.
bool write_file(const std::string& path, const std::string& data) {
  std::string tmp = path + ".tmp";
  FILE* f = fl_fopen(tmp.c_str(), "wb");
  if (!f) return false;
#ifndef _WIN32
  fchmod(fileno(f), 0600);   // solo la persona: es una base de datos de contraseñas
#endif
  bool ok = std::fwrite(data.data(), 1, data.size(), f) == data.size();
  ok = std::fflush(f) == 0 && ok;
  ok = std::fclose(f) == 0 && ok;
  if (!ok) {
    std::remove(tmp.c_str());
    return false;
  }
#ifdef _WIN32
  std::remove(path.c_str());
#endif
  return std::rename(tmp.c_str(), path.c_str()) == 0;
}
bool file_exists(const std::string& path) {
  FILE* f = fl_fopen(path.c_str(), "rb");
  if (!f) return false;
  std::fclose(f);
  return true;
}

using Bytes = std::vector<uint8_t>;

inline uint32_t rotr32(uint32_t x, int n) { return (x >> n) | (x << (32 - n)); }
inline uint32_t rotl32(uint32_t x, int n) { return (x << n) | (x >> (32 - n)); }
inline uint64_t rotr64(uint64_t x, int n) { return (x >> n) | (x << (64 - n)); }
inline uint32_t le32(const uint8_t* p) { return (uint32_t)p[0] | (uint32_t)p[1] << 8 | (uint32_t)p[2] << 16 | (uint32_t)p[3] << 24; }
inline uint64_t le64(const uint8_t* p) { return (uint64_t)le32(p) | (uint64_t)le32(p + 4) << 32; }
inline void put32(uint8_t* p, uint32_t v) {
  for (int i = 0; i < 4; i++) p[i] = (uint8_t)(v >> (8 * i));
}
inline void put64(uint8_t* p, uint64_t v) {
  for (int i = 0; i < 8; i++) p[i] = (uint8_t)(v >> (8 * i));
}
void add32(Bytes& b, uint32_t v) {
  uint8_t t[4];
  put32(t, v);
  b.insert(b.end(), t, t + 4);
}
void add64(Bytes& b, uint64_t v) {
  uint8_t t[8];
  put64(t, v);
  b.insert(b.end(), t, t + 8);
}
Bytes bytes(const std::string& s) { return Bytes(s.begin(), s.end()); }
Bytes cat(const Bytes& a, const Bytes& b) {
  Bytes o = a;
  o.insert(o.end(), b.begin(), b.end());
  return o;
}
// Borrar de verdad lo secreto (que el compilador no se salte el borrado).
void wipe(void* p, size_t n) {
  volatile uint8_t* v = (volatile uint8_t*)p;
  while (n--) *v++ = 0;
}
void wipe(Bytes& b) {
  if (!b.empty()) wipe(b.data(), b.size());
  b.clear();
}
void wipe(std::string& s) {
  if (!s.empty()) wipe(&s[0], s.size());
  s.clear();
}
std::string hex(const Bytes& b) {
  static const char* d = "0123456789abcdef";
  std::string o;
  for (uint8_t c : b) {
    o += d[c >> 4];
    o += d[c & 15];
  }
  return o;
}
Bytes unhex(const std::string& s) {
  Bytes o;
  auto v = [](char c) { return c >= 'a' ? c - 'a' + 10 : c >= 'A' ? c - 'A' + 10 : c - '0'; };
  for (size_t i = 0; i + 1 < s.size(); i += 2) o.push_back((uint8_t)(v(s[i]) << 4 | v(s[i + 1])));
  return o;
}

// ---- SHA-256
struct Sha256 {
  uint32_t h[8] = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19};
  uint8_t buf[64];
  size_t n = 0;
  uint64_t total = 0;
  void block(const uint8_t* p) {
    static const uint32_t K[64] = {
        0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be,
        0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa,
        0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85,
        0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
        0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f,
        0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2};
    uint32_t w[64];
    for (int i = 0; i < 16; i++) w[i] = (uint32_t)p[4 * i] << 24 | (uint32_t)p[4 * i + 1] << 16 | (uint32_t)p[4 * i + 2] << 8 | p[4 * i + 3];
    for (int i = 16; i < 64; i++) {
      uint32_t s0 = rotr32(w[i - 15], 7) ^ rotr32(w[i - 15], 18) ^ (w[i - 15] >> 3);
      uint32_t s1 = rotr32(w[i - 2], 17) ^ rotr32(w[i - 2], 19) ^ (w[i - 2] >> 10);
      w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    uint32_t a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
    for (int i = 0; i < 64; i++) {
      uint32_t t1 = hh + (rotr32(e, 6) ^ rotr32(e, 11) ^ rotr32(e, 25)) + ((e & f) ^ (~e & g)) + K[i] + w[i];
      uint32_t t2 = (rotr32(a, 2) ^ rotr32(a, 13) ^ rotr32(a, 22)) + ((a & b) ^ (a & c) ^ (b & c));
      hh = g;
      g = f;
      f = e;
      e = d + t1;
      d = c;
      c = b;
      b = a;
      a = t1 + t2;
    }
    h[0] += a;
    h[1] += b;
    h[2] += c;
    h[3] += d;
    h[4] += e;
    h[5] += f;
    h[6] += g;
    h[7] += hh;
  }
  void update(const uint8_t* p, size_t len) {
    total += len;
    while (len) {
      size_t k = std::min(len, 64 - n);
      std::memcpy(buf + n, p, k);
      n += k;
      p += k;
      len -= k;
      if (n == 64) {
        block(buf);
        n = 0;
      }
    }
  }
  void update(const Bytes& b) { update(b.data(), b.size()); }
  Bytes final() {
    uint64_t bits = total * 8;
    uint8_t pad = 0x80;
    update(&pad, 1);
    uint8_t z = 0;
    while (n != 56) update(&z, 1);
    uint8_t L[8];
    for (int i = 0; i < 8; i++) L[i] = (uint8_t)(bits >> (56 - 8 * i));
    update(L, 8);
    Bytes o(32);
    for (int i = 0; i < 8; i++)
      for (int k = 0; k < 4; k++) o[(size_t)(4 * i + k)] = (uint8_t)(h[i] >> (24 - 8 * k));
    wipe(buf, sizeof buf);
    return o;
  }
};
Bytes sha256(const Bytes& b) {
  Sha256 s;
  s.update(b);
  return s.final();
}

// ---- SHA-512
struct Sha512 {
  uint64_t h[8] = {0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, 0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
                   0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL, 0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL};
  uint8_t buf[128];
  size_t n = 0;
  uint64_t total = 0;
  void block(const uint8_t* p) {
    static const uint64_t K[80] = {
        0x428a2f98d728ae22ULL, 0x7137449123ef65cdULL, 0xb5c0fbcfec4d3b2fULL, 0xe9b5dba58189dbbcULL, 0x3956c25bf348b538ULL, 0x59f111f1b605d019ULL,
        0x923f82a4af194f9bULL, 0xab1c5ed5da6d8118ULL, 0xd807aa98a3030242ULL, 0x12835b0145706fbeULL, 0x243185be4ee4b28cULL, 0x550c7dc3d5ffb4e2ULL,
        0x72be5d74f27b896fULL, 0x80deb1fe3b1696b1ULL, 0x9bdc06a725c71235ULL, 0xc19bf174cf692694ULL, 0xe49b69c19ef14ad2ULL, 0xefbe4786384f25e3ULL,
        0x0fc19dc68b8cd5b5ULL, 0x240ca1cc77ac9c65ULL, 0x2de92c6f592b0275ULL, 0x4a7484aa6ea6e483ULL, 0x5cb0a9dcbd41fbd4ULL, 0x76f988da831153b5ULL,
        0x983e5152ee66dfabULL, 0xa831c66d2db43210ULL, 0xb00327c898fb213fULL, 0xbf597fc7beef0ee4ULL, 0xc6e00bf33da88fc2ULL, 0xd5a79147930aa725ULL,
        0x06ca6351e003826fULL, 0x142929670a0e6e70ULL, 0x27b70a8546d22ffcULL, 0x2e1b21385c26c926ULL, 0x4d2c6dfc5ac42aedULL, 0x53380d139d95b3dfULL,
        0x650a73548baf63deULL, 0x766a0abb3c77b2a8ULL, 0x81c2c92e47edaee6ULL, 0x92722c851482353bULL, 0xa2bfe8a14cf10364ULL, 0xa81a664bbc423001ULL,
        0xc24b8b70d0f89791ULL, 0xc76c51a30654be30ULL, 0xd192e819d6ef5218ULL, 0xd69906245565a910ULL, 0xf40e35855771202aULL, 0x106aa07032bbd1b8ULL,
        0x19a4c116b8d2d0c8ULL, 0x1e376c085141ab53ULL, 0x2748774cdf8eeb99ULL, 0x34b0bcb5e19b48a8ULL, 0x391c0cb3c5c95a63ULL, 0x4ed8aa4ae3418acbULL,
        0x5b9cca4f7763e373ULL, 0x682e6ff3d6b2b8a3ULL, 0x748f82ee5defb2fcULL, 0x78a5636f43172f60ULL, 0x84c87814a1f0ab72ULL, 0x8cc702081a6439ecULL,
        0x90befffa23631e28ULL, 0xa4506cebde82bde9ULL, 0xbef9a3f7b2c67915ULL, 0xc67178f2e372532bULL, 0xca273eceea26619cULL, 0xd186b8c721c0c207ULL,
        0xeada7dd6cde0eb1eULL, 0xf57d4f7fee6ed178ULL, 0x06f067aa72176fbaULL, 0x0a637dc5a2c898a6ULL, 0x113f9804bef90daeULL, 0x1b710b35131c471bULL,
        0x28db77f523047d84ULL, 0x32caab7b40c72493ULL, 0x3c9ebe0a15c9bebcULL, 0x431d67c49c100d4cULL, 0x4cc5d4becb3e42b6ULL, 0x597f299cfc657e2aULL,
        0x5fcb6fab3ad6faecULL, 0x6c44198c4a475817ULL};
    uint64_t w[80];
    for (int i = 0; i < 16; i++) {
      w[i] = 0;
      for (int k = 0; k < 8; k++) w[i] = w[i] << 8 | p[8 * i + k];
    }
    for (int i = 16; i < 80; i++) {
      uint64_t s0 = rotr64(w[i - 15], 1) ^ rotr64(w[i - 15], 8) ^ (w[i - 15] >> 7);
      uint64_t s1 = rotr64(w[i - 2], 19) ^ rotr64(w[i - 2], 61) ^ (w[i - 2] >> 6);
      w[i] = w[i - 16] + s0 + w[i - 7] + s1;
    }
    uint64_t a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7];
    for (int i = 0; i < 80; i++) {
      uint64_t t1 = hh + (rotr64(e, 14) ^ rotr64(e, 18) ^ rotr64(e, 41)) + ((e & f) ^ (~e & g)) + K[i] + w[i];
      uint64_t t2 = (rotr64(a, 28) ^ rotr64(a, 34) ^ rotr64(a, 39)) + ((a & b) ^ (a & c) ^ (b & c));
      hh = g;
      g = f;
      f = e;
      e = d + t1;
      d = c;
      c = b;
      b = a;
      a = t1 + t2;
    }
    h[0] += a;
    h[1] += b;
    h[2] += c;
    h[3] += d;
    h[4] += e;
    h[5] += f;
    h[6] += g;
    h[7] += hh;
  }
  void update(const uint8_t* p, size_t len) {
    total += len;
    while (len) {
      size_t k = std::min(len, 128 - n);
      std::memcpy(buf + n, p, k);
      n += k;
      p += k;
      len -= k;
      if (n == 128) {
        block(buf);
        n = 0;
      }
    }
  }
  void update(const Bytes& b) { update(b.data(), b.size()); }
  Bytes final() {
    uint64_t bits = total * 8;
    uint8_t pad = 0x80;
    update(&pad, 1);
    uint8_t z = 0;
    while (n != 112) update(&z, 1);
    uint8_t L[16] = {0};
    for (int i = 0; i < 8; i++) L[8 + i] = (uint8_t)(bits >> (56 - 8 * i));
    update(L, 16);
    Bytes o(64);
    for (int i = 0; i < 8; i++)
      for (int k = 0; k < 8; k++) o[(size_t)(8 * i + k)] = (uint8_t)(h[i] >> (56 - 8 * k));
    wipe(buf, sizeof buf);
    return o;
  }
};
Bytes sha512(const Bytes& b) {
  Sha512 s;
  s.update(b);
  return s.final();
}
Bytes hmac_sha256(const Bytes& key, const Bytes& msg) {
  Bytes k = key.size() > 64 ? sha256(key) : key;
  k.resize(64, 0);
  Bytes ip(64), op(64);
  for (int i = 0; i < 64; i++) {
    ip[(size_t)i] = k[(size_t)i] ^ 0x36;
    op[(size_t)i] = k[(size_t)i] ^ 0x5c;
  }
  Sha256 in;
  in.update(ip);
  in.update(msg);
  Sha256 out;
  out.update(op);
  out.update(in.final());
  wipe(k);
  return out.final();
}
// Comparar sin que el tiempo diga dónde está la diferencia.
bool same(const Bytes& a, const Bytes& b) {
  if (a.size() != b.size()) return false;
  uint8_t d = 0;
  for (size_t i = 0; i < a.size(); i++) d |= a[i] ^ b[i];
  return d == 0;
}

// ---- AES-256 (con tablas: la clave de AES-KDF de KeePass cifra millones de veces)
struct Aes256 {
  uint32_t ek[60], dk[60];
  static const uint8_t* sbox() {
    static uint8_t s[256];
    static bool done = false;
    if (!done) {
      // La S-box: el inverso en GF(2^8) y la transformación afín.
      uint8_t p = 1, q = 1;
      do {
        p = (uint8_t)(p ^ (p << 1) ^ (p & 0x80 ? 0x1b : 0));
        q ^= (uint8_t)(q << 1);
        q ^= (uint8_t)(q << 2);
        q ^= (uint8_t)(q << 4);
        if (q & 0x80) q ^= 0x09;
        uint8_t x = (uint8_t)(q ^ (uint8_t)((q << 1) | (q >> 7)) ^ (uint8_t)((q << 2) | (q >> 6)) ^ (uint8_t)((q << 3) | (q >> 5)) ^
                      (uint8_t)((q << 4) | (q >> 4)));
        s[p] = (uint8_t)(x ^ 0x63);
      } while (p != 1);
      s[0] = 0x63;
      done = true;
    }
    return s;
  }
  static const uint8_t* inv_sbox() {
    static uint8_t s[256];
    static bool done = false;
    if (!done) {
      const uint8_t* f = sbox();
      for (int i = 0; i < 256; i++) s[f[i]] = (uint8_t)i;
      done = true;
    }
    return s;
  }
  static uint8_t xt(uint8_t x) { return (uint8_t)((x << 1) ^ (x & 0x80 ? 0x1b : 0)); }
  static uint8_t mul(uint8_t a, uint8_t b) {
    uint8_t r = 0;
    while (b) {
      if (b & 1) r ^= a;
      a = xt(a);
      b >>= 1;
    }
    return r;
  }
  // Te: SubBytes + MixColumns de una vez (una consulta por byte).
  static const uint32_t* te() {
    static uint32_t t[256];
    static bool done = false;
    if (!done) {
      const uint8_t* s = sbox();
      for (int i = 0; i < 256; i++) {
        uint8_t v = s[i];
        t[i] = (uint32_t)mul(v, 2) << 24 | (uint32_t)v << 16 | (uint32_t)v << 8 | mul(v, 3);
      }
      done = true;
    }
    return t;
  }
  explicit Aes256(const uint8_t* key) {
    const uint8_t* s = sbox();
    for (int i = 0; i < 8; i++) ek[i] = (uint32_t)key[4 * i] << 24 | (uint32_t)key[4 * i + 1] << 16 | (uint32_t)key[4 * i + 2] << 8 | key[4 * i + 3];
    uint32_t rcon = 0x01000000;
    for (int i = 8; i < 60; i++) {
      uint32_t t = ek[i - 1];
      if (i % 8 == 0) {
        t = (uint32_t)s[(t >> 16) & 255] << 24 | (uint32_t)s[(t >> 8) & 255] << 16 | (uint32_t)s[t & 255] << 8 | s[t >> 24];
        t ^= rcon;
        rcon = (uint32_t)xt((uint8_t)(rcon >> 24)) << 24;
      } else if (i % 8 == 4) {
        t = (uint32_t)s[t >> 24] << 24 | (uint32_t)s[(t >> 16) & 255] << 16 | (uint32_t)s[(t >> 8) & 255] << 8 | s[t & 255];
      }
      ek[i] = ek[i - 8] ^ t;
    }
    for (int i = 0; i < 60; i++) dk[i] = ek[i];
  }
  ~Aes256() {
    wipe(ek, sizeof ek);
    wipe(dk, sizeof dk);
  }
  void encrypt(const uint8_t* in, uint8_t* out) const {
    const uint32_t* T = te();
    const uint8_t* S = sbox();
    uint32_t s0 = ((uint32_t)in[0] << 24 | (uint32_t)in[1] << 16 | (uint32_t)in[2] << 8 | in[3]) ^ ek[0];
    uint32_t s1 = ((uint32_t)in[4] << 24 | (uint32_t)in[5] << 16 | (uint32_t)in[6] << 8 | in[7]) ^ ek[1];
    uint32_t s2 = ((uint32_t)in[8] << 24 | (uint32_t)in[9] << 16 | (uint32_t)in[10] << 8 | in[11]) ^ ek[2];
    uint32_t s3 = ((uint32_t)in[12] << 24 | (uint32_t)in[13] << 16 | (uint32_t)in[14] << 8 | in[15]) ^ ek[3];
    auto r = [](uint32_t x, int n) { return n ? (x >> n) | (x << (32 - n)) : x; };
    for (int round = 1; round < 14; round++) {
      const uint32_t* k = ek + 4 * round;
      uint32_t t0 = T[s0 >> 24] ^ r(T[(s1 >> 16) & 255], 8) ^ r(T[(s2 >> 8) & 255], 16) ^ r(T[s3 & 255], 24) ^ k[0];
      uint32_t t1 = T[s1 >> 24] ^ r(T[(s2 >> 16) & 255], 8) ^ r(T[(s3 >> 8) & 255], 16) ^ r(T[s0 & 255], 24) ^ k[1];
      uint32_t t2 = T[s2 >> 24] ^ r(T[(s3 >> 16) & 255], 8) ^ r(T[(s0 >> 8) & 255], 16) ^ r(T[s1 & 255], 24) ^ k[2];
      uint32_t t3 = T[s3 >> 24] ^ r(T[(s0 >> 16) & 255], 8) ^ r(T[(s1 >> 8) & 255], 16) ^ r(T[s2 & 255], 24) ^ k[3];
      s0 = t0;
      s1 = t1;
      s2 = t2;
      s3 = t3;
    }
    const uint32_t* k = ek + 56;
    uint32_t o[4] = {
        ((uint32_t)S[s0 >> 24] << 24 | (uint32_t)S[(s1 >> 16) & 255] << 16 | (uint32_t)S[(s2 >> 8) & 255] << 8 | S[s3 & 255]) ^ k[0],
        ((uint32_t)S[s1 >> 24] << 24 | (uint32_t)S[(s2 >> 16) & 255] << 16 | (uint32_t)S[(s3 >> 8) & 255] << 8 | S[s0 & 255]) ^ k[1],
        ((uint32_t)S[s2 >> 24] << 24 | (uint32_t)S[(s3 >> 16) & 255] << 16 | (uint32_t)S[(s0 >> 8) & 255] << 8 | S[s1 & 255]) ^ k[2],
        ((uint32_t)S[s3 >> 24] << 24 | (uint32_t)S[(s0 >> 16) & 255] << 16 | (uint32_t)S[(s1 >> 8) & 255] << 8 | S[s2 & 255]) ^ k[3]};
    for (int i = 0; i < 4; i++)
      for (int b = 0; b < 4; b++) out[4 * i + b] = (uint8_t)(o[i] >> (24 - 8 * b));
  }
  // Descifrar (byte a byte: solo se usa con los datos, no millones de veces).
  void decrypt(const uint8_t* in, uint8_t* out) const {
    const uint8_t* IS = inv_sbox();
    uint8_t st[16];
    auto add_key = [&](int round) {
      for (int c = 0; c < 4; c++)
        for (int b = 0; b < 4; b++) st[4 * c + b] ^= (uint8_t)(ek[4 * round + c] >> (24 - 8 * b));
    };
    std::memcpy(st, in, 16);
    add_key(14);
    for (int round = 13; round >= 0; round--) {
      // InvShiftRows y InvSubBytes.
      uint8_t t[16];
      for (int c = 0; c < 4; c++)
        for (int r = 0; r < 4; r++) t[4 * ((c + r) % 4) + r] = st[4 * c + r];
      for (int i = 0; i < 16; i++) st[i] = IS[t[i]];
      add_key(round);
      if (round == 0) break;
      for (int c = 0; c < 4; c++) {
        uint8_t a0 = st[4 * c], a1 = st[4 * c + 1], a2 = st[4 * c + 2], a3 = st[4 * c + 3];
        st[4 * c] = (uint8_t)(mul(a0, 14) ^ mul(a1, 11) ^ mul(a2, 13) ^ mul(a3, 9));
        st[4 * c + 1] = (uint8_t)(mul(a0, 9) ^ mul(a1, 14) ^ mul(a2, 11) ^ mul(a3, 13));
        st[4 * c + 2] = (uint8_t)(mul(a0, 13) ^ mul(a1, 9) ^ mul(a2, 14) ^ mul(a3, 11));
        st[4 * c + 3] = (uint8_t)(mul(a0, 11) ^ mul(a1, 13) ^ mul(a2, 9) ^ mul(a3, 14));
      }
    }
    std::memcpy(out, st, 16);
    wipe(st, 16);
  }
};
// AES-256-CBC con relleno PKCS#7 (como KeePass).
Bytes aes_cbc_encrypt(const Bytes& key, const Bytes& iv, const Bytes& data) {
  Aes256 a(key.data());
  Bytes in = data;
  size_t pad = 16 - in.size() % 16;
  in.insert(in.end(), pad, (uint8_t)pad);
  Bytes out(in.size());
  uint8_t prev[16];
  std::memcpy(prev, iv.data(), 16);
  for (size_t i = 0; i < in.size(); i += 16) {
    uint8_t x[16];
    for (int k = 0; k < 16; k++) x[k] = in[i + (size_t)k] ^ prev[k];
    a.encrypt(x, &out[i]);
    std::memcpy(prev, &out[i], 16);
  }
  wipe(in);
  return out;
}
bool aes_cbc_decrypt(const Bytes& key, const Bytes& iv, const Bytes& data, Bytes& out) {
  if (data.empty() || data.size() % 16 || iv.size() != 16) return false;
  Aes256 a(key.data());
  out.assign(data.size(), 0);
  uint8_t prev[16];
  std::memcpy(prev, iv.data(), 16);
  for (size_t i = 0; i < data.size(); i += 16) {
    uint8_t x[16];
    a.decrypt(&data[i], x);
    for (int k = 0; k < 16; k++) out[i + (size_t)k] = x[k] ^ prev[k];
    std::memcpy(prev, &data[i], 16);
  }
  uint8_t pad = out.back();
  if (pad < 1 || pad > 16) return false;
  for (size_t i = out.size() - pad; i < out.size(); i++)
    if (out[i] != pad) return false;
  out.resize(out.size() - pad);
  return true;
}

// ---- ChaCha20 (RFC 7539) y Salsa20 (el de las bases de datos antiguas, KDBX 3)
struct ChaCha20 {
  uint32_t st[16];
  uint8_t ks[64];
  size_t used = 64;
  ChaCha20(const uint8_t* key, const uint8_t* nonce12, uint32_t counter = 0) {
    st[0] = 0x61707865;
    st[1] = 0x3320646e;
    st[2] = 0x79622d32;
    st[3] = 0x6b206574;
    for (int i = 0; i < 8; i++) st[4 + i] = le32(key + 4 * i);
    st[12] = counter;
    for (int i = 0; i < 3; i++) st[13 + i] = le32(nonce12 + 4 * i);
  }
  ~ChaCha20() {
    wipe(st, sizeof st);
    wipe(ks, sizeof ks);
  }
  static void qr(uint32_t& a, uint32_t& b, uint32_t& c, uint32_t& d) {
    a += b;
    d = rotl32(d ^ a, 16);
    c += d;
    b = rotl32(b ^ c, 12);
    a += b;
    d = rotl32(d ^ a, 8);
    c += d;
    b = rotl32(b ^ c, 7);
  }
  void next() {
    uint32_t x[16];
    std::memcpy(x, st, sizeof x);
    for (int i = 0; i < 10; i++) {
      qr(x[0], x[4], x[8], x[12]);
      qr(x[1], x[5], x[9], x[13]);
      qr(x[2], x[6], x[10], x[14]);
      qr(x[3], x[7], x[11], x[15]);
      qr(x[0], x[5], x[10], x[15]);
      qr(x[1], x[6], x[11], x[12]);
      qr(x[2], x[7], x[8], x[13]);
      qr(x[3], x[4], x[9], x[14]);
    }
    for (int i = 0; i < 16; i++) put32(ks + 4 * i, x[i] + st[i]);
    st[12]++;
    used = 0;
  }
  void apply(uint8_t* p, size_t n) {
    for (size_t i = 0; i < n; i++) {
      if (used == 64) next();
      p[i] ^= ks[used++];
    }
  }
};
struct Salsa20 {
  uint32_t st[16];
  uint8_t ks[64];
  size_t used = 64;
  Salsa20(const uint8_t* key, const uint8_t* nonce8) {
    st[0] = 0x61707865;
    st[5] = 0x3320646e;
    st[10] = 0x79622d32;
    st[15] = 0x6b206574;
    for (int i = 0; i < 4; i++) st[1 + i] = le32(key + 4 * i);
    for (int i = 0; i < 4; i++) st[11 + i] = le32(key + 16 + 4 * i);
    st[6] = le32(nonce8);
    st[7] = le32(nonce8 + 4);
    st[8] = st[9] = 0;
  }
  ~Salsa20() {
    wipe(st, sizeof st);
    wipe(ks, sizeof ks);
  }
  void next() {
    uint32_t x[16];
    std::memcpy(x, st, sizeof x);
    auto q = [&](int a, int b, int c, int d) {
      x[b] ^= rotl32(x[a] + x[d], 7);
      x[c] ^= rotl32(x[b] + x[a], 9);
      x[d] ^= rotl32(x[c] + x[b], 13);
      x[a] ^= rotl32(x[d] + x[c], 18);
    };
    for (int i = 0; i < 10; i++) {
      q(0, 4, 8, 12);
      q(5, 9, 13, 1);
      q(10, 14, 2, 6);
      q(15, 3, 7, 11);
      q(0, 1, 2, 3);
      q(5, 6, 7, 4);
      q(10, 11, 8, 9);
      q(15, 12, 13, 14);
    }
    for (int i = 0; i < 16; i++) put32(ks + 4 * i, x[i] + st[i]);
    if (++st[8] == 0) st[9]++;
    used = 0;
  }
  void apply(uint8_t* p, size_t n) {
    for (size_t i = 0; i < n; i++) {
      if (used == 64) next();
      p[i] ^= ks[used++];
    }
  }
};

// ---- BLAKE2b (RFC 7693): la función de Argon2
struct Blake2b {
  uint64_t h[8];
  uint8_t buf[128];
  size_t n = 0;
  uint64_t t = 0;
  size_t outlen;
  static constexpr uint64_t IV[8] = {0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, 0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
                                     0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL, 0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL};
  explicit Blake2b(size_t out) : outlen(out) {
    for (int i = 0; i < 8; i++) h[i] = IV[i];
    h[0] ^= 0x01010000 ^ (uint64_t)outlen;
  }
  void compress(const uint8_t* p, bool last) {
    static const uint8_t S[12][16] = {{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}, {14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3},
                                      {11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4}, {7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8},
                                      {9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13}, {2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9},
                                      {12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11}, {13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10},
                                      {6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5}, {10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0},
                                      {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15}, {14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3}};
    uint64_t m[16], v[16];
    for (int i = 0; i < 16; i++) m[i] = le64(p + 8 * i);
    for (int i = 0; i < 8; i++) {
      v[i] = h[i];
      v[i + 8] = IV[i];
    }
    v[12] ^= t;
    if (last) v[14] = ~v[14];
    auto G = [&](int a, int b, int c, int d, uint64_t x, uint64_t y) {
      v[a] = v[a] + v[b] + x;
      v[d] = rotr64(v[d] ^ v[a], 32);
      v[c] = v[c] + v[d];
      v[b] = rotr64(v[b] ^ v[c], 24);
      v[a] = v[a] + v[b] + y;
      v[d] = rotr64(v[d] ^ v[a], 16);
      v[c] = v[c] + v[d];
      v[b] = rotr64(v[b] ^ v[c], 63);
    };
    for (int r = 0; r < 12; r++) {
      const uint8_t* s = S[r];
      G(0, 4, 8, 12, m[s[0]], m[s[1]]);
      G(1, 5, 9, 13, m[s[2]], m[s[3]]);
      G(2, 6, 10, 14, m[s[4]], m[s[5]]);
      G(3, 7, 11, 15, m[s[6]], m[s[7]]);
      G(0, 5, 10, 15, m[s[8]], m[s[9]]);
      G(1, 6, 11, 12, m[s[10]], m[s[11]]);
      G(2, 7, 8, 13, m[s[12]], m[s[13]]);
      G(3, 4, 9, 14, m[s[14]], m[s[15]]);
    }
    for (int i = 0; i < 8; i++) h[i] ^= v[i] ^ v[i + 8];
  }
  void update(const uint8_t* p, size_t len) {
    while (len) {
      if (n == 128) {
        t += 128;
        compress(buf, false);
        n = 0;
      }
      size_t k = std::min(len, 128 - n);
      std::memcpy(buf + n, p, k);
      n += k;
      p += k;
      len -= k;
    }
  }
  void update(const Bytes& b) { update(b.data(), b.size()); }
  Bytes final() {
    t += n;
    std::memset(buf + n, 0, 128 - n);
    compress(buf, true);
    Bytes o(outlen);
    for (size_t i = 0; i < outlen; i++) o[i] = (uint8_t)(h[i / 8] >> (8 * (i % 8)));
    return o;
  }
};
constexpr uint64_t Blake2b::IV[8];
Bytes blake2b(const Bytes& in, size_t outlen) {
  Blake2b b(outlen);
  b.update(in);
  return b.final();
}

// ---- Argon2 (RFC 9106): la derivación de la clave de KDBX 4 (Argon2d y Argon2id)
// H' de longitud variable.
Bytes blake2b_long(const Bytes& in, uint32_t T) {
  Bytes len(4);
  put32(len.data(), T);
  if (T <= 64) {
    Blake2b b(T);
    b.update(len);
    b.update(in);
    return b.final();
  }
  Bytes out;
  Blake2b b(64);
  b.update(len);
  b.update(in);
  Bytes v = b.final();
  out.insert(out.end(), v.begin(), v.begin() + 32);
  uint32_t r = (T + 31) / 32 - 2;
  for (uint32_t i = 1; i < r; i++) {
    v = blake2b(v, 64);
    out.insert(out.end(), v.begin(), v.begin() + 32);
  }
  v = blake2b(v, T - 32 * r);
  out.insert(out.end(), v.begin(), v.end());
  return out;
}
enum Argon2Type { ARGON2_D = 0, ARGON2_I = 1, ARGON2_ID = 2 };
struct Block {
  uint64_t v[128];
};
inline uint64_t blamka(uint64_t x, uint64_t y) { return x + y + 2 * (uint64_t)(uint32_t)x * (uint32_t)y; }
inline void gb(uint64_t& a, uint64_t& b, uint64_t& c, uint64_t& d) {
  a = blamka(a, b);
  d = rotr64(d ^ a, 32);
  c = blamka(c, d);
  b = rotr64(b ^ c, 24);
  a = blamka(a, b);
  d = rotr64(d ^ a, 16);
  c = blamka(c, d);
  b = rotr64(b ^ c, 63);
}
inline void perm(uint64_t* v, int i0, int i1, int i2, int i3, int i4, int i5, int i6, int i7, int i8, int i9, int i10, int i11, int i12,
                 int i13, int i14, int i15) {
  gb(v[i0], v[i4], v[i8], v[i12]);
  gb(v[i1], v[i5], v[i9], v[i13]);
  gb(v[i2], v[i6], v[i10], v[i14]);
  gb(v[i3], v[i7], v[i11], v[i15]);
  gb(v[i0], v[i5], v[i10], v[i15]);
  gb(v[i1], v[i6], v[i11], v[i12]);
  gb(v[i2], v[i7], v[i8], v[i13]);
  gb(v[i3], v[i4], v[i9], v[i14]);
}
// G(X, Y): out = P(X ^ Y) ^ X ^ Y (y, si «xor_out», también ^ out).
void fill_block(const Block& x, const Block& y, Block& out, bool xor_out) {
  Block r, tmp;
  for (int i = 0; i < 128; i++) r.v[i] = x.v[i] ^ y.v[i];
  tmp = r;
  if (xor_out)
    for (int i = 0; i < 128; i++) tmp.v[i] ^= out.v[i];
  uint64_t* v = r.v;
  for (int i = 0; i < 8; i++) {
    int b = 16 * i;
    perm(v, b, b + 1, b + 2, b + 3, b + 4, b + 5, b + 6, b + 7, b + 8, b + 9, b + 10, b + 11, b + 12, b + 13, b + 14, b + 15);
  }
  for (int i = 0; i < 8; i++) {
    int b = 2 * i;
    perm(v, b, b + 1, b + 16, b + 17, b + 32, b + 33, b + 48, b + 49, b + 64, b + 65, b + 80, b + 81, b + 96, b + 97, b + 112, b + 113);
  }
  for (int i = 0; i < 128; i++) out.v[i] = tmp.v[i] ^ r.v[i];
}
Bytes argon2(Argon2Type type, const Bytes& pwd, const Bytes& salt, uint32_t t_cost, uint32_t m_kib, uint32_t lanes, uint32_t taglen,
             const Bytes& secret = Bytes(), const Bytes& ad = Bytes(), uint32_t version = 0x13) {
  if (lanes < 1) lanes = 1;
  if (t_cost < 1) t_cost = 1;
  if (m_kib < 8 * lanes) m_kib = 8 * lanes;
  Bytes h0in;
  add32(h0in, lanes);
  add32(h0in, taglen);
  add32(h0in, m_kib);
  add32(h0in, t_cost);
  add32(h0in, version);
  add32(h0in, (uint32_t)type);
  add32(h0in, (uint32_t)pwd.size());
  h0in.insert(h0in.end(), pwd.begin(), pwd.end());
  add32(h0in, (uint32_t)salt.size());
  h0in.insert(h0in.end(), salt.begin(), salt.end());
  add32(h0in, (uint32_t)secret.size());
  h0in.insert(h0in.end(), secret.begin(), secret.end());
  add32(h0in, (uint32_t)ad.size());
  h0in.insert(h0in.end(), ad.begin(), ad.end());
  Bytes h0 = blake2b(h0in, 64);
  wipe(h0in);
  uint32_t mem = 4 * lanes * (m_kib / (4 * lanes));
  uint32_t q = mem / lanes, seg = q / 4;
  std::vector<Block> B(mem);
  auto at = [&](uint32_t l, uint32_t c) -> Block& { return B[(size_t)l * q + c]; };
  for (uint32_t l = 0; l < lanes; l++)
    for (uint32_t c = 0; c < 2; c++) {
      Bytes in = h0;
      add32(in, c);
      add32(in, l);
      Bytes blk = blake2b_long(in, 1024);
      for (int i = 0; i < 128; i++) at(l, c).v[i] = le64(&blk[(size_t)i * 8]);
      wipe(blk);
    }
  Block zero{}, input{}, addr{};
  for (uint32_t pass = 0; pass < t_cost; pass++)
    for (uint32_t slice = 0; slice < 4; slice++)
      for (uint32_t lane = 0; lane < lanes; lane++) {
        bool indep = type == ARGON2_I || (type == ARGON2_ID && pass == 0 && slice < 2);
        if (indep) {
          input = zero;
          input.v[0] = pass;
          input.v[1] = lane;
          input.v[2] = slice;
          input.v[3] = mem;
          input.v[4] = t_cost;
          input.v[5] = (uint64_t)type;
        }
        uint32_t start = (pass == 0 && slice == 0) ? 2 : 0;
        if (indep && start == 2) {
          input.v[6]++;
          fill_block(zero, input, addr, false);
          fill_block(zero, addr, addr, false);
        }
        for (uint32_t i = start; i < seg; i++) {
          uint32_t col = slice * seg + i;
          uint32_t prev = col == 0 ? q - 1 : col - 1;
          uint64_t rnd;
          if (indep) {
            if (i % 128 == 0) {
              input.v[6]++;
              fill_block(zero, input, addr, false);
              fill_block(zero, addr, addr, false);
            }
            rnd = addr.v[i % 128];
          } else {
            rnd = at(lane, prev).v[0];
          }
          uint32_t j1 = (uint32_t)rnd, j2 = (uint32_t)(rnd >> 32);
          uint32_t ref_lane = (pass == 0 && slice == 0) ? lane : j2 % lanes;
          bool same_lane = ref_lane == lane;
          uint32_t area;
          if (pass == 0) {
            if (slice == 0) area = i - 1;
            else area = same_lane ? slice * seg + i - 1 : slice * seg + (i == 0 ? (uint32_t)-1 : 0);
          } else {
            area = same_lane ? q - seg + i - 1 : q - seg + (i == 0 ? (uint32_t)-1 : 0);
          }
          uint64_t x = ((uint64_t)j1 * j1) >> 32;
          uint64_t y = ((uint64_t)area * x) >> 32;
          uint32_t rel = area - 1 - (uint32_t)y;
          uint32_t first = pass == 0 ? 0 : (slice == 3 ? 0 : (slice + 1) * seg);
          uint32_t ref = (first + rel) % q;
          fill_block(at(lane, prev), at(ref_lane, ref), at(lane, col), pass != 0 && version == 0x13);
        }
      }
  Block fin = at(0, q - 1);
  for (uint32_t l = 1; l < lanes; l++)
    for (int i = 0; i < 128; i++) fin.v[i] ^= at(l, q - 1).v[i];
  Bytes fb(1024);
  for (int i = 0; i < 128; i++) put64(&fb[(size_t)i * 8], fin.v[i]);
  Bytes tag = blake2b_long(fb, taglen);
  wipe(fb);
  for (auto& b : B) wipe(b.v, sizeof b.v);
  wipe(h0);
  return tag;
}

// ---- azar del sistema (para las claves, las semillas y el generador de contraseñas)
void random_bytes(uint8_t* p, size_t n) {
#ifdef __APPLE__
  arc4random_buf(p, n);
#elif defined(_WIN32)
  for (size_t i = 0; i < n; i++) {
    unsigned int v = 0;
    rand_s(&v);
    p[i] = (uint8_t)v;
  }
#else
  FILE* f = std::fopen("/dev/urandom", "rb");
  size_t got = f ? std::fread(p, 1, n, f) : 0;
  if (f) std::fclose(f);
  if (got != n) std::abort();   // sin azar de verdad, mejor no seguir
#endif
}
Bytes random_bytes(size_t n) {
  Bytes b(n);
  random_bytes(b.data(), n);
  return b;
}
// Un número al azar en [0, n) sin sesgo.
uint32_t random_below(uint32_t n) {
  if (n <= 1) return 0;
  uint32_t limit = 0xffffffffu - 0xffffffffu % n, v;
  do {
    uint8_t b[4];
    random_bytes(b, 4);
    v = le32(b);
  } while (v >= limit);
  return v % n;
}

// ============================================================ base64, gzip y XML
std::string b64(const Bytes& b) {
  static const char* T = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
  std::string o;
  size_t i = 0;
  for (; i + 2 < b.size(); i += 3) {
    uint32_t v = (uint32_t)b[i] << 16 | (uint32_t)b[i + 1] << 8 | b[i + 2];
    o += T[v >> 18];
    o += T[(v >> 12) & 63];
    o += T[(v >> 6) & 63];
    o += T[v & 63];
  }
  if (i + 1 == b.size()) {
    uint32_t v = (uint32_t)b[i] << 16;
    o += T[v >> 18];
    o += T[(v >> 12) & 63];
    o += "==";
  } else if (i + 2 == b.size()) {
    uint32_t v = (uint32_t)b[i] << 16 | (uint32_t)b[i + 1] << 8;
    o += T[v >> 18];
    o += T[(v >> 12) & 63];
    o += T[(v >> 6) & 63];
    o += '=';
  }
  return o;
}
Bytes unb64(const std::string& s) {
  Bytes o;
  uint32_t v = 0;
  int n = 0;
  for (char c : s) {
    int d = c >= 'A' && c <= 'Z' ? c - 'A' : c >= 'a' && c <= 'z' ? c - 'a' + 26 : c >= '0' && c <= '9' ? c - '0' + 52 : c == '+' ? 62 : c == '/' ? 63 : -1;
    if (d < 0) continue;
    v = v << 6 | (uint32_t)d;
    if (++n == 4) {
      o.push_back((uint8_t)(v >> 16));
      o.push_back((uint8_t)(v >> 8));
      o.push_back((uint8_t)v);
      v = 0;
      n = 0;
    }
  }
  if (n == 2) o.push_back((uint8_t)(v >> 4));
  if (n == 3) {
    o.push_back((uint8_t)(v >> 10));
    o.push_back((uint8_t)(v >> 2));
  }
  return o;
}
uint32_t crc32(const Bytes& b) {
  static uint32_t t[256];
  static bool done = false;
  if (!done) {
    for (uint32_t i = 0; i < 256; i++) {
      uint32_t c = i;
      for (int k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >> 1) : c >> 1;
      t[i] = c;
    }
    done = true;
  }
  uint32_t c = 0xffffffff;
  for (uint8_t x : b) c = t[(c ^ x) & 255] ^ (c >> 8);
  return c ^ 0xffffffff;
}
// Descomprimir DEFLATE (RFC 1951): KeePass guarda la base de datos con gzip.
struct Inflate {
  const uint8_t* in;
  size_t len, pos = 0;
  uint32_t bitbuf = 0;
  int bitcnt = 0;
  Bytes out;
  bool err = false;
  int bits(int need) {
    while (bitcnt < need) {
      if (pos >= len) {
        err = true;
        return 0;
      }
      bitbuf |= (uint32_t)in[pos++] << bitcnt;
      bitcnt += 8;
    }
    int v = (int)(bitbuf & ((1u << need) - 1));
    bitbuf >>= need;
    bitcnt -= need;
    return v;
  }
  struct Huff {
    short count[16], symbol[320];
  };
  bool build(Huff& h, const short* lengths, int n) {
    for (int i = 0; i < 16; i++) h.count[i] = 0;
    for (int i = 0; i < n; i++) h.count[lengths[i]]++;
    if (h.count[0] == n) return true;
    int left = 1;
    for (int i = 1; i < 16; i++) {
      left <<= 1;
      left -= h.count[i];
      if (left < 0) return false;
    }
    short offs[16];
    offs[1] = 0;
    for (int i = 1; i < 15; i++) offs[i + 1] = (short)(offs[i] + h.count[i]);
    for (int i = 0; i < n; i++)
      if (lengths[i]) h.symbol[offs[lengths[i]]++] = (short)i;
    return true;
  }
  int decode(const Huff& h) {
    int code = 0, first = 0, index = 0;
    for (int l = 1; l < 16; l++) {
      code |= bits(1);
      if (err) return -1;
      int count = h.count[l];
      if (code - count < first) return h.symbol[index + (code - first)];
      index += count;
      first += count;
      first <<= 1;
      code <<= 1;
    }
    err = true;
    return -1;
  }
  bool codes(const Huff& lc, const Huff& dc) {
    static const short lbase[29] = {3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31, 35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258};
    static const short lext[29] = {0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0};
    static const short dbase[30] = {1,   2,   3,   4,   5,   7,    9,    13,   17,   25,   33,   49,   65,    97,    129,
                                    193, 257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577};
    static const short dext[30] = {0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13};
    while (true) {
      int sym = decode(lc);
      if (err || sym < 0) return false;
      if (sym < 256) out.push_back((uint8_t)sym);
      else if (sym == 256) return true;
      else {
        sym -= 257;
        if (sym >= 29) return false;
        int l = lbase[sym] + bits(lext[sym]);
        int d = decode(dc);
        if (err || d < 0 || d >= 30) return false;
        size_t dist = (size_t)(dbase[d] + bits(dext[d]));
        if (err || dist > out.size()) return false;
        for (int i = 0; i < l; i++) out.push_back(out[out.size() - dist]);
      }
    }
  }
  bool run() {
    int last;
    do {
      last = bits(1);
      int type = bits(2);
      if (err) return false;
      if (type == 0) {
        bitbuf = 0;
        bitcnt = 0;
        if (pos + 4 > len) return false;
        size_t n = in[pos] | (size_t)in[pos + 1] << 8;
        pos += 4;
        if (pos + n > len) return false;
        out.insert(out.end(), in + pos, in + pos + n);
        pos += n;
      } else if (type == 1) {
        static Huff lc, dc;
        static bool made = false;
        if (!made) {
          short l[288];
          for (int i = 0; i < 144; i++) l[i] = 8;
          for (int i = 144; i < 256; i++) l[i] = 9;
          for (int i = 256; i < 280; i++) l[i] = 7;
          for (int i = 280; i < 288; i++) l[i] = 8;
          build(lc, l, 288);
          short d[30];
          for (int i = 0; i < 30; i++) d[i] = 5;
          build(dc, d, 30);
          made = true;
        }
        if (!codes(lc, dc)) return false;
      } else if (type == 2) {
        static const short order[19] = {16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15};
        int nlen = bits(5) + 257, ndist = bits(5) + 1, ncode = bits(4) + 4;
        if (err || nlen > 286 || ndist > 30) return false;
        short lengths[320] = {0};
        for (int i = 0; i < ncode; i++) lengths[order[i]] = (short)bits(3);
        Huff lencode, lc, dc;
        if (!build(lencode, lengths, 19)) return false;
        int i = 0;
        while (i < nlen + ndist) {
          int sym = decode(lencode);
          if (err || sym < 0) return false;
          if (sym < 16) lengths[i++] = (short)sym;
          else {
            short l = 0;
            int rep;
            if (sym == 16) {
              if (i == 0) return false;
              l = lengths[i - 1];
              rep = 3 + bits(2);
            } else if (sym == 17) rep = 3 + bits(3);
            else rep = 11 + bits(7);
            if (i + rep > nlen + ndist) return false;
            while (rep--) lengths[i++] = l;
          }
        }
        if (!build(lc, lengths, nlen) || !build(dc, lengths + nlen, ndist)) return false;
        if (!codes(lc, dc)) return false;
      } else return false;
    } while (!last);
    return true;
  }
};
bool gunzip(const Bytes& gz, Bytes& out) {
  if (gz.size() < 18 || gz[0] != 0x1f || gz[1] != 0x8b || gz[2] != 8) return false;
  uint8_t flg = gz[3];
  size_t p = 10;
  if (flg & 4) {
    if (p + 2 > gz.size()) return false;
    p += 2 + (gz[p] | (size_t)gz[p + 1] << 8);
  }
  if (flg & 8)
    while (p < gz.size() && gz[p++]) {
    }
  if (flg & 16)
    while (p < gz.size() && gz[p++]) {
    }
  if (flg & 2) p += 2;
  if (p >= gz.size()) return false;
  Inflate inf;
  inf.in = gz.data() + p;
  inf.len = gz.size() - p;
  if (!inf.run()) return false;
  size_t end = p + inf.pos;
  if (end + 8 > gz.size()) return false;
  if (le32(&gz[end]) != crc32(inf.out) || le32(&gz[end + 4]) != (uint32_t)inf.out.size()) return false;
  out.swap(inf.out);
  return true;
}
// Comprimir en gzip sin comprimir de verdad (bloques «stored»): lo leen KeePass y KeePassXC.
Bytes gzip_stored(const Bytes& data) {
  Bytes o = {0x1f, 0x8b, 8, 0, 0, 0, 0, 0, 0, 255};
  size_t p = 0;
  do {
    size_t n = std::min<size_t>(65535, data.size() - p);
    bool last = p + n >= data.size();
    o.push_back(last ? 1 : 0);
    o.push_back((uint8_t)n);
    o.push_back((uint8_t)(n >> 8));
    o.push_back((uint8_t)~n);
    o.push_back((uint8_t)(~n >> 8));
    o.insert(o.end(), data.begin() + (long)p, data.begin() + (long)(p + n));
    p += n;
  } while (p < data.size());
  add32(o, crc32(data));
  add32(o, (uint32_t)data.size());
  return o;
}

// ---- XML: un árbol que se guarda entero (lo que DMarlonPass no conoce, también)
struct Node {
  std::string name, text;
  std::vector<std::pair<std::string, std::string>> attrs;
  std::vector<std::unique_ptr<Node>> kids;
  Node* parent = nullptr;
  Node* child(const std::string& n) const {
    for (const auto& k : kids)
      if (k->name == n) return k.get();
    return nullptr;
  }
  std::vector<Node*> children(const std::string& n) const {
    std::vector<Node*> o;
    for (const auto& k : kids)
      if (k->name == n) o.push_back(k.get());
    return o;
  }
  Node* add(const std::string& n, const std::string& t = "") {
    kids.push_back(std::unique_ptr<Node>(new Node()));
    Node* k = kids.back().get();
    k->name = n;
    k->text = t;
    k->parent = this;
    return k;
  }
  Node* ensure(const std::string& n) {
    Node* c = child(n);
    return c ? c : add(n);
  }
  std::string attr(const std::string& n) const {
    for (const auto& a : attrs)
      if (a.first == n) return a.second;
    return "";
  }
  void set_attr(const std::string& n, const std::string& v) {
    for (auto& a : attrs)
      if (a.first == n) {
        a.second = v;
        return;
      }
    attrs.push_back({n, v});
  }
  std::string get(const std::string& n) const {
    Node* c = child(n);
    return c ? c->text : "";
  }
  void set(const std::string& n, const std::string& v) { ensure(n)->text = v; }
  std::unique_ptr<Node> clone() const {
    std::unique_ptr<Node> c(new Node());
    c->name = name;
    c->text = text;
    c->attrs = attrs;
    for (const auto& k : kids) {
      c->kids.push_back(k->clone());
      c->kids.back()->parent = c.get();
    }
    return c;
  }
  std::unique_ptr<Node> detach(Node* k) {
    for (size_t i = 0; i < kids.size(); i++)
      if (kids[i].get() == k) {
        std::unique_ptr<Node> out = std::move(kids[i]);
        kids.erase(kids.begin() + (long)i);
        out->parent = nullptr;
        return out;
      }
    return nullptr;
  }
  Node* adopt(std::unique_ptr<Node> k, long at = -1) {
    k->parent = this;
    Node* raw = k.get();
    if (at < 0 || at > (long)kids.size()) kids.push_back(std::move(k));
    else kids.insert(kids.begin() + at, std::move(k));
    return raw;
  }
  // Borrar lo secreto al cerrar (el texto de cada nodo).
  void wipe_all() {
    kp::wipe(text);
    for (auto& a : attrs) kp::wipe(a.second);
    for (auto& k : kids) k->wipe_all();
  }
};
struct XmlReader {
  const std::string& s;
  size_t i = 0;
  bool ok = true;
  explicit XmlReader(const std::string& src) : s(src) {}
  static std::string unescape(const std::string& t) {
    std::string o;
    for (size_t k = 0; k < t.size(); k++) {
      if (t[k] != '&') {
        o += t[k];
        continue;
      }
      size_t e = t.find(';', k);
      if (e == std::string::npos) {
        o += t[k];
        continue;
      }
      std::string ent = t.substr(k + 1, e - k - 1);
      if (ent == "lt") o += '<';
      else if (ent == "gt") o += '>';
      else if (ent == "amp") o += '&';
      else if (ent == "quot") o += '"';
      else if (ent == "apos") o += '\'';
      else if (!ent.empty() && ent[0] == '#') {
        uint32_t cp = ent.size() > 1 && (ent[1] == 'x' || ent[1] == 'X') ? (uint32_t)std::strtoul(ent.c_str() + 2, nullptr, 16)
                                                                         : (uint32_t)std::strtoul(ent.c_str() + 1, nullptr, 10);
        if (cp < 0x80) o += (char)cp;
        else if (cp < 0x800) {
          o += (char)(0xC0 | (cp >> 6));
          o += (char)(0x80 | (cp & 0x3F));
        } else if (cp < 0x10000) {
          o += (char)(0xE0 | (cp >> 12));
          o += (char)(0x80 | ((cp >> 6) & 0x3F));
          o += (char)(0x80 | (cp & 0x3F));
        } else {
          o += (char)(0xF0 | (cp >> 18));
          o += (char)(0x80 | ((cp >> 12) & 0x3F));
          o += (char)(0x80 | ((cp >> 6) & 0x3F));
          o += (char)(0x80 | (cp & 0x3F));
        }
      } else {
        o += t.substr(k, e - k + 1);
      }
      k = e;
    }
    return o;
  }
  void skip_misc() {
    while (i < s.size()) {
      while (i < s.size() && std::isspace((unsigned char)s[i])) i++;
      if (s.compare(i, 4, "<!--") == 0) {
        size_t e = s.find("-->", i);
        i = e == std::string::npos ? s.size() : e + 3;
      } else if (s.compare(i, 2, "<?") == 0) {
        size_t e = s.find("?>", i);
        i = e == std::string::npos ? s.size() : e + 2;
      } else if (s.compare(i, 9, "<!DOCTYPE") == 0) {
        size_t e = s.find('>', i);
        i = e == std::string::npos ? s.size() : e + 1;
      } else break;
    }
  }
  std::unique_ptr<Node> element(int depth = 0) {
    if (depth > 200 || i >= s.size() || s[i] != '<') {
      ok = false;
      return nullptr;
    }
    std::unique_ptr<Node> n(new Node());
    i++;
    size_t st = i;
    while (i < s.size() && !std::isspace((unsigned char)s[i]) && s[i] != '>' && s[i] != '/') i++;
    n->name = s.substr(st, i - st);
    // Los atributos.
    while (i < s.size()) {
      while (i < s.size() && std::isspace((unsigned char)s[i])) i++;
      if (s[i] == '/' || s[i] == '>') break;
      size_t a = i;
      while (i < s.size() && s[i] != '=' && !std::isspace((unsigned char)s[i])) i++;
      std::string an = s.substr(a, i - a);
      while (i < s.size() && (s[i] == '=' || std::isspace((unsigned char)s[i]))) i++;
      if (i >= s.size()) break;
      char q = s[i++];
      size_t e = s.find(q, i);
      if (e == std::string::npos) {
        ok = false;
        return nullptr;
      }
      n->attrs.push_back({an, unescape(s.substr(i, e - i))});
      i = e + 1;
    }
    if (i < s.size() && s[i] == '/') {
      i += 2;
      return n;
    }
    i++;
    std::string text;
    while (i < s.size()) {
      if (s.compare(i, 2, "</") == 0) {
        size_t e = s.find('>', i);
        i = e == std::string::npos ? s.size() : e + 1;
        break;
      }
      if (s.compare(i, 4, "<!--") == 0) {
        size_t e = s.find("-->", i);
        i = e == std::string::npos ? s.size() : e + 3;
        continue;
      }
      if (s.compare(i, 9, "<![CDATA[") == 0) {
        size_t e = s.find("]]>", i);
        if (e == std::string::npos) {
          ok = false;
          return nullptr;
        }
        text += s.substr(i + 9, e - i - 9);
        i = e + 3;
        continue;
      }
      if (s[i] == '<') {
        auto k = element(depth + 1);
        if (!k) return nullptr;
        k->parent = n.get();
        n->kids.push_back(std::move(k));
        continue;
      }
      size_t e = s.find('<', i);
      if (e == std::string::npos) e = s.size();
      text += unescape(s.substr(i, e - i));
      i = e;
    }
    if (n->kids.empty()) n->text = text;
    return n;
  }
};
std::unique_ptr<Node> parse_xml(const std::string& text) {
  XmlReader r(text);
  r.skip_misc();
  auto n = r.element();
  return r.ok ? std::move(n) : nullptr;
}
std::string xml_escape(const std::string& s, bool attr) {
  std::string o;
  for (unsigned char c : s) {
    if (c == '&') o += "&amp;";
    else if (c == '<') o += "&lt;";
    else if (c == '>') o += "&gt;";
    else if (c == '"' && attr) o += "&quot;";
    else if (c < 0x20 && c != '\t' && c != '\n' && c != '\r') continue;   // no valen en XML
    else o += (char)c;
  }
  return o;
}
void write_xml(const Node& n, std::string& o, int depth) {
  o.append((size_t)depth, '\t');
  o += "<" + n.name;
  for (const auto& a : n.attrs) o += " " + a.first + "=\"" + xml_escape(a.second, true) + "\"";
  if (n.kids.empty()) {
    if (n.text.empty()) o += " />\n";
    else o += ">" + xml_escape(n.text, false) + "</" + n.name + ">\n";
    return;
  }
  o += ">\n";
  for (const auto& k : n.kids) write_xml(*k, o, depth + 1);
  o.append((size_t)depth, '\t');
  o += "</" + n.name + ">\n";
}

// ============================================================ el formato KDBX
const char* const UUID_AES = "31c1f2e6bf714350be5805216afc5aff";
const char* const UUID_CHACHA = "d6038a2b8b6f4cb5a524339a31dbb59a";
const char* const UUID_TWOFISH = "ad68f29f576f4bb9a36ad47af965346c";
const char* const UUID_AESKDF = "c9d9f39a628a4460bf740d08c18a4fea";
const char* const UUID_ARGON2D = "ef636ddf8c29444b91f7a9a403e30a0c";
const char* const UUID_ARGON2ID = "9e298b1956db4773b23dfc3ec6f0a1e6";
enum Cipher { C_AES = 0, C_CHACHA = 1 };
enum KdfType { K_AESKDF = 0, K_ARGON2D = 1, K_ARGON2ID = 2 };
struct Kdf {
  KdfType type = K_ARGON2D;
  uint64_t iterations = 10;            // Argon2: pasadas; AES-KDF: rondas
  uint64_t memory = 64ull << 20;       // Argon2: bytes
  uint32_t parallelism = 2;
  uint32_t version = 0x13;
  Bytes salt;
};
struct Database {
  uint16_t major = 4, minor = 0;   // la versión del archivo (KDBX 3.1 se guarda como 4.0)
  Cipher cipher = C_AES;
  bool compressed = true;
  Kdf kdf;
  Bytes public_custom;             // datos públicos del encabezado (se guardan tal cual)
  std::unique_ptr<Node> xml;
  std::vector<Bytes> binaries;     // los adjuntos (KDBX 4: en el encabezado interno)
  std::vector<uint8_t> binary_flags;
  bool from_v3 = false;
};
// La clave compuesta: SHA-256 de la contraseña y, si hay, de la clave del archivo de clave.
Bytes composite_key(const std::string& password, const Bytes& keyfile_key) {
  Bytes parts = sha256(bytes(password));
  if (!keyfile_key.empty()) parts.insert(parts.end(), keyfile_key.begin(), keyfile_key.end());
  Bytes k = sha256(parts);
  wipe(parts);
  return k;
}
// El archivo de clave de KeePass: XML (versión 1 o 2), 32 bytes, 64 hexadecimales o, si no, el SHA-256 del archivo.
Bytes keyfile_key(const Bytes& file) {
  std::string s(file.begin(), file.end());
  if (s.find("<KeyFile") != std::string::npos) {
    auto x = parse_xml(s);
    if (x) {
      Node* key = x->child("Key");
      Node* data = key ? key->child("Data") : nullptr;
      if (data) {
        std::string ver = x->child("Meta") ? x->child("Meta")->get("Version") : "";
        if (ver.rfind("2.", 0) == 0) {
          std::string h;
          for (char c : data->text)
            if (std::isxdigit((unsigned char)c)) h += c;
          if (h.size() == 64) return unhex(h);
        } else {
          Bytes b = unb64(data->text);
          if (b.size() == 32) return b;
        }
      }
    }
  }
  if (file.size() == 32) return file;
  if (file.size() == 64) {
    bool all = true;
    for (uint8_t c : file) all = all && std::isxdigit(c);
    if (all) return unhex(s);
  }
  return sha256(file);
}
// Un archivo de clave nuevo (XML versión 2.0, como KeePass 2.47+).
std::string make_keyfile() {
  Bytes k = random_bytes(32);
  std::string h = hex(k);
  for (auto& c : h) c = (char)std::toupper((unsigned char)c);
  Bytes kh = sha256(k);
  std::string hash = hex(Bytes(kh.begin(), kh.begin() + 4));
  for (auto& c : hash) c = (char)std::toupper((unsigned char)c);
  std::string d;
  for (size_t i = 0; i < h.size(); i += 8) d += (i ? (i % 32 == 0 ? "\n\t\t\t" : " ") : "") + h.substr(i, 8);
  wipe(k);
  return "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<KeyFile>\n\t<Meta>\n\t\t<Version>2.0</Version>\n\t</Meta>\n\t<Key>\n\t\t<Data Hash=\"" + hash +
         "\">\n\t\t\t" + d + "\n\t\t</Data>\n\t</Key>\n</KeyFile>\n";
}
Bytes transform_key(const Kdf& kdf, const Bytes& composite) {
  if (kdf.type == K_AESKDF) {
    Aes256 a(kdf.salt.data());
    Bytes k = composite;
    for (uint64_t r = 0; r < kdf.iterations; r++) {
      a.encrypt(k.data(), k.data());
      a.encrypt(k.data() + 16, k.data() + 16);
    }
    Bytes out = sha256(k);
    wipe(k);
    return out;
  }
  return argon2(kdf.type == K_ARGON2ID ? ARGON2_ID : ARGON2_D, composite, kdf.salt, (uint32_t)kdf.iterations,
                (uint32_t)std::min<uint64_t>(kdf.memory / 1024, 0xffffffffu), kdf.parallelism, 32, Bytes(), Bytes(), kdf.version);
}
// El diccionario de parámetros de KDBX 4 (VariantDictionary).
struct Variant {
  uint8_t type;
  Bytes value;
};
bool read_variants(const Bytes& b, std::vector<std::pair<std::string, Variant>>& out) {
  if (b.size() < 2 || b[1] != 1) return false;
  size_t p = 2;
  while (p < b.size()) {
    uint8_t type = b[p++];
    if (type == 0) return true;
    if (p + 4 > b.size()) return false;
    uint32_t kl = le32(&b[p]);
    p += 4;
    if (p + kl + 4 > b.size()) return false;
    std::string k(b.begin() + (long)p, b.begin() + (long)(p + kl));
    p += kl;
    uint32_t vl = le32(&b[p]);
    p += 4;
    if (p + vl > b.size()) return false;
    out.push_back({k, {type, Bytes(b.begin() + (long)p, b.begin() + (long)(p + vl))}});
    p += vl;
  }
  return false;
}
Bytes write_variants(const std::vector<std::pair<std::string, Variant>>& items) {
  Bytes b = {0x00, 0x01};
  for (const auto& it : items) {
    b.push_back(it.second.type);
    add32(b, (uint32_t)it.first.size());
    b.insert(b.end(), it.first.begin(), it.first.end());
    add32(b, (uint32_t)it.second.value.size());
    b.insert(b.end(), it.second.value.begin(), it.second.value.end());
  }
  b.push_back(0);
  return b;
}
uint64_t vnum(const Variant& v) { return v.value.size() >= 8 ? le64(v.value.data()) : v.value.size() >= 4 ? le32(v.value.data()) : 0; }

// Los valores protegidos (las contraseñas) van cifrados dentro del XML con un flujo aparte.
struct InnerStream {
  std::unique_ptr<ChaCha20> chacha;
  std::unique_ptr<Salsa20> salsa;
  InnerStream(uint32_t id, const Bytes& key) {
    if (id == 3) {
      Bytes h = sha512(key);
      chacha.reset(new ChaCha20(h.data(), h.data() + 32));
      wipe(h);
    } else if (id == 2) {
      Bytes h = sha256(key);
      static const uint8_t nonce[8] = {0xE8, 0x30, 0x09, 0x4B, 0x97, 0x20, 0x5D, 0x2A};
      salsa.reset(new Salsa20(h.data(), nonce));
      wipe(h);
    }
  }
  bool ok() const { return chacha || salsa; }
  void apply(Bytes& b) {
    if (chacha) chacha->apply(b.data(), b.size());
    else if (salsa) salsa->apply(b.data(), b.size());
  }
};
void unprotect(Node* n, InnerStream& st) {
  if (n->attr("Protected") == "True") {
    Bytes b = unb64(n->text);
    st.apply(b);
    n->text.assign(b.begin(), b.end());
    wipe(b);
  }
  for (auto& k : n->kids) unprotect(k.get(), st);
}
void protect(const Node* n, InnerStream& st, std::string& o, int depth);

const char* const ERR_FORMAT = "format";
const char* const ERR_KEY = "key";
const char* const ERR_CORRUPT = "corrupt";
const char* const ERR_CIPHER = "cipher";
const char* const ERR_VERSION = "version";

// ---- abrir
bool open_kdbx(const Bytes& f, const Bytes& composite, Database& db, std::string& err) {
  db = Database();
  if (f.size() < 12 || le32(&f[0]) != 0x9AA2D903 || le32(&f[4]) != 0xB54BFB67) {
    err = ERR_FORMAT;
    return false;
  }
  db.minor = (uint16_t)(f[8] | f[9] << 8);
  db.major = (uint16_t)(f[10] | f[11] << 8);
  if (db.major != 3 && db.major != 4) {
    err = ERR_VERSION;
    return false;
  }
  bool v4 = db.major == 4;
  size_t p = 12;
  Bytes cipher_id, master_seed, iv, kdf_params, transform_seed, stream_key, start_bytes;
  uint64_t transform_rounds = 0;
  uint32_t stream_id = 0;
  uint32_t compression = 0;
  while (true) {
    if (p + (v4 ? 5 : 3) > f.size()) {
      err = ERR_CORRUPT;
      return false;
    }
    uint8_t id = f[p++];
    uint32_t sz = v4 ? le32(&f[p]) : (uint32_t)(f[p] | f[p + 1] << 8);
    p += v4 ? 4 : 2;
    if (p + sz > f.size()) {
      err = ERR_CORRUPT;
      return false;
    }
    Bytes v(f.begin() + (long)p, f.begin() + (long)(p + sz));
    p += sz;
    if (id == 0) break;
    if (id == 2) cipher_id = v;
    else if (id == 3 && v.size() >= 4) compression = le32(v.data());
    else if (id == 4) master_seed = v;
    else if (id == 5) transform_seed = v;
    else if (id == 6 && v.size() >= 8) transform_rounds = le64(v.data());
    else if (id == 7) iv = v;
    else if (id == 8) stream_key = v;
    else if (id == 9) start_bytes = v;
    else if (id == 10 && v.size() >= 4) stream_id = le32(v.data());
    else if (id == 11) kdf_params = v;
    else if (id == 12) db.public_custom = v;
  }
  Bytes header(f.begin(), f.begin() + (long)p);
  std::string cid = hex(cipher_id);
  if (cid == UUID_AES) db.cipher = C_AES;
  else if (cid == UUID_CHACHA) db.cipher = C_CHACHA;
  else {
    err = ERR_CIPHER;   // Twofish u otro: no lo hace DMarlonPass
    return false;
  }
  db.compressed = compression == 1;
  if (master_seed.size() != 32) {
    err = ERR_CORRUPT;
    return false;
  }
  // La clave derivada.
  if (v4) {
    std::vector<std::pair<std::string, Variant>> vars;
    if (!read_variants(kdf_params, vars)) {
      err = ERR_CORRUPT;
      return false;
    }
    std::string kid;
    for (const auto& kv : vars) {
      if (kv.first == "$UUID") kid = hex(kv.second.value);
      else if (kv.first == "S") db.kdf.salt = kv.second.value;
      else if (kv.first == "R" || kv.first == "I") db.kdf.iterations = vnum(kv.second);
      else if (kv.first == "M") db.kdf.memory = vnum(kv.second);
      else if (kv.first == "P") db.kdf.parallelism = (uint32_t)vnum(kv.second);
      else if (kv.first == "V") db.kdf.version = (uint32_t)vnum(kv.second);
    }
    if (kid == UUID_AESKDF) db.kdf.type = K_AESKDF;
    else if (kid == UUID_ARGON2D) db.kdf.type = K_ARGON2D;
    else if (kid == UUID_ARGON2ID) db.kdf.type = K_ARGON2ID;
    else {
      err = ERR_CIPHER;
      return false;
    }
    if (db.kdf.salt.size() < 8 || (db.kdf.type == K_AESKDF && db.kdf.salt.size() != 32)) {
      err = ERR_CORRUPT;
      return false;
    }
  } else {
    db.kdf.type = K_AESKDF;
    db.kdf.salt = transform_seed;
    db.kdf.iterations = transform_rounds;
    if (transform_seed.size() != 32) {
      err = ERR_CORRUPT;
      return false;
    }
  }
  Bytes transformed = transform_key(db.kdf, composite);
  Bytes key = sha256(cat(master_seed, transformed));
  Bytes payload, plain;
  if (v4) {
    if (p + 64 > f.size()) {
      err = ERR_CORRUPT;
      return false;
    }
    Bytes hash(f.begin() + (long)p, f.begin() + (long)p + 32), hmac(f.begin() + (long)p + 32, f.begin() + (long)p + 64);
    p += 64;
    if (!same(hash, sha256(header))) {
      err = ERR_CORRUPT;
      return false;
    }
    Bytes mix = cat(master_seed, transformed);
    mix.push_back(1);
    Bytes hmac_key = sha512(mix);
    wipe(mix);
    auto block_key = [&](uint64_t index) {
      Bytes b;
      add64(b, index);
      b.insert(b.end(), hmac_key.begin(), hmac_key.end());
      Bytes k = sha512(b);
      wipe(b);
      return k;
    };
    if (!same(hmac, hmac_sha256(block_key(0xFFFFFFFFFFFFFFFFull), header))) {
      err = ERR_KEY;   // la contraseña o el archivo de clave no son los de esta base de datos
      wipe(hmac_key);
      return false;
    }
    // Los bloques, cada uno con su HMAC.
    for (uint64_t index = 0;; index++) {
      if (p + 36 > f.size()) {
        err = ERR_CORRUPT;
        return false;
      }
      Bytes mac(f.begin() + (long)p, f.begin() + (long)p + 32);
      uint32_t sz = le32(&f[p + 32]);
      p += 36;
      if (p + sz > f.size()) {
        err = ERR_CORRUPT;
        return false;
      }
      Bytes msg;
      add64(msg, index);
      add32(msg, sz);
      msg.insert(msg.end(), f.begin() + (long)p, f.begin() + (long)(p + sz));
      if (!same(mac, hmac_sha256(block_key(index), msg))) {
        err = ERR_CORRUPT;
        return false;
      }
      if (sz == 0) break;
      payload.insert(payload.end(), f.begin() + (long)p, f.begin() + (long)(p + sz));
      p += sz;
    }
    wipe(hmac_key);
  } else {
    payload.assign(f.begin() + (long)p, f.end());
  }
  bool dec_ok;
  if (db.cipher == C_AES) dec_ok = aes_cbc_decrypt(key, iv, payload, plain);
  else {
    dec_ok = iv.size() == 12;
    plain = payload;
    if (dec_ok) {
      ChaCha20 c(key.data(), iv.data());
      c.apply(plain.data(), plain.size());
    }
  }
  wipe(key);
  wipe(transformed);
  if (!dec_ok) {
    err = v4 ? ERR_CORRUPT : ERR_KEY;
    return false;
  }
  Bytes content;
  if (!v4) {
    // KDBX 3: los bytes de comprobación y luego bloques con su SHA-256.
    if (plain.size() < 32 || !same(Bytes(plain.begin(), plain.begin() + 32), start_bytes)) {
      err = ERR_KEY;
      return false;
    }
    size_t q = 32;
    while (true) {
      if (q + 40 > plain.size()) {
        err = ERR_CORRUPT;
        return false;
      }
      Bytes h(plain.begin() + (long)q + 4, plain.begin() + (long)q + 36);
      uint32_t sz = le32(&plain[q + 36]);
      q += 40;
      if (sz == 0) break;
      if (q + sz > plain.size()) {
        err = ERR_CORRUPT;
        return false;
      }
      Bytes blk(plain.begin() + (long)q, plain.begin() + (long)(q + sz));
      if (!same(h, sha256(blk))) {
        err = ERR_CORRUPT;
        return false;
      }
      content.insert(content.end(), blk.begin(), blk.end());
      q += sz;
    }
    wipe(plain);
  } else content.swap(plain);
  if (db.compressed) {
    Bytes un;
    if (!gunzip(content, un)) {
      err = ERR_CORRUPT;
      return false;
    }
    wipe(content);
    content.swap(un);
  }
  size_t q = 0;
  if (v4) {
    // El encabezado interno: el flujo de los valores protegidos y los adjuntos.
    while (true) {
      if (q + 5 > content.size()) {
        err = ERR_CORRUPT;
        return false;
      }
      uint8_t id = content[q];
      uint32_t sz = le32(&content[q + 1]);
      q += 5;
      if (q + sz > content.size()) {
        err = ERR_CORRUPT;
        return false;
      }
      Bytes v(content.begin() + (long)q, content.begin() + (long)(q + sz));
      q += sz;
      if (id == 0) break;
      if (id == 1 && v.size() >= 4) stream_id = le32(v.data());
      else if (id == 2) stream_key = v;
      else if (id == 3 && !v.empty()) {
        db.binary_flags.push_back(v[0]);
        db.binaries.push_back(Bytes(v.begin() + 1, v.end()));
      }
    }
  }
  std::string xmltext(content.begin() + (long)q, content.end());
  wipe(content);
  db.xml = parse_xml(xmltext);
  wipe(xmltext);
  if (!db.xml || db.xml->name != "KeePassFile") {
    err = ERR_CORRUPT;
    return false;
  }
  InnerStream st(stream_id, stream_key);
  if (!st.ok()) {
    err = ERR_CIPHER;
    return false;
  }
  unprotect(db.xml.get(), st);
  wipe(stream_key);
  if (!v4) {
    db.from_v3 = true;
    // Los adjuntos de KDBX 3 van en Meta/Binaries: pasan al encabezado interno de KDBX 4.
    Node* meta = db.xml->child("Meta");
    Node* bins = meta ? meta->child("Binaries") : nullptr;
    if (bins) {
      std::map<int, Bytes> byid;
      for (Node* b : bins->children("Binary")) {
        Bytes data = b->attr("Protected") == "True" ? Bytes(b->text.begin(), b->text.end()) : unb64(b->text);
        if (b->attr("Compressed") == "True") {
          Bytes un;
          if (gunzip(data, un)) data.swap(un);
        }
        byid[std::atoi(b->attr("ID").c_str())] = data;
      }
      for (auto& kv : byid) {
        db.binaries.push_back(kv.second);
        db.binary_flags.push_back(0);
      }
      meta->detach(bins);
    }
    if (meta) {
      Node* hh = meta->child("HeaderHash");
      if (hh) meta->detach(hh);
    }
  }
  return true;
}

// Las fechas: KDBX 4 las guarda como segundos desde el año 1 (en base64); KDBX 3, como texto.
const long long KDBX_EPOCH = 62135596800LL;   // del 1/1/0001 al 1/1/1970
long long days_civil(int y, unsigned m, unsigned d) {
  y -= m <= 2;
  const long long era = (y >= 0 ? y : y - 399) / 400;
  const unsigned yoe = (unsigned)(y - era * 400);
  const unsigned doy = (153 * (m + (m > 2 ? -3 : 9)) + 2) / 5 + d - 1;
  const unsigned doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
  return era * 146097 + (long long)doe - 719468;
}
std::string kdbx_time(long long unix_t) {
  Bytes b;
  add64(b, (uint64_t)(unix_t + KDBX_EPOCH));
  return b64(b);
}
long long parse_time(const std::string& s) {
  if (s.size() >= 19 && s[4] == '-' && s[10] == 'T') {
    int y = std::atoi(s.substr(0, 4).c_str()), mo = std::atoi(s.substr(5, 2).c_str()), d = std::atoi(s.substr(8, 2).c_str());
    int h = std::atoi(s.substr(11, 2).c_str()), mi = std::atoi(s.substr(14, 2).c_str()), se = std::atoi(s.substr(17, 2).c_str());
    return days_civil(y, (unsigned)mo, (unsigned)d) * 86400 + h * 3600 + mi * 60 + se;
  }
  Bytes b = unb64(s);
  if (b.size() == 8) return (long long)le64(b.data()) - KDBX_EPOCH;
  return 0;
}
bool time_name(const std::string& n) {
  return (n.size() > 4 && n.compare(n.size() - 4, 4, "Time") == 0) || (n.size() > 7 && n.compare(n.size() - 7, 7, "Changed") == 0) ||
         n == "LocationChanged";
}
void times_to_v4(Node* n) {
  if (n->kids.empty() && time_name(n->name) && n->text.size() >= 19 && n->text[4] == '-') n->text = kdbx_time(parse_time(n->text));
  for (auto& k : n->kids) times_to_v4(k.get());
}

// ---- guardar (siempre KDBX 4)
void protect(const Node* n, InnerStream& st, std::string& o, int depth) {
  o.append((size_t)depth, '\t');
  o += "<" + n->name;
  for (const auto& a : n->attrs) o += " " + a.first + "=\"" + xml_escape(a.second, true) + "\"";
  if (n->kids.empty()) {
    std::string t = n->text;
    if (n->attr("Protected") == "True") {
      Bytes b(t.begin(), t.end());
      st.apply(b);
      t = b64(b);
      wipe(b);
      o += ">" + t + "</" + n->name + ">\n";
      return;
    }
    if (t.empty()) o += " />\n";
    else o += ">" + xml_escape(t, false) + "</" + n->name + ">\n";
    return;
  }
  o += ">\n";
  for (const auto& k : n->kids) protect(k.get(), st, o, depth + 1);
  o.append((size_t)depth, '\t');
  o += "</" + n->name + ">\n";
}
bool save_kdbx(Database& db, const Bytes& composite, Bytes& out, std::string& err) {
  if (!db.xml) {
    err = ERR_CORRUPT;
    return false;
  }
  if (db.from_v3) {
    times_to_v4(db.xml.get());
    db.from_v3 = false;
    db.major = 4;
    db.minor = 0;
  }
  if (db.major != 4) db.major = 4;
  // Cada vez, semillas nuevas (como KeePass): la clave derivada cambia en cada guardado.
  Bytes master_seed = random_bytes(32), iv = random_bytes(db.cipher == C_AES ? 16 : 12);
  db.kdf.salt = random_bytes(32);
  std::vector<std::pair<std::string, Variant>> vars;
  if (db.kdf.type == K_AESKDF) {
    vars.push_back({"$UUID", {0x42, unhex(UUID_AESKDF)}});
    Bytes r;
    add64(r, db.kdf.iterations);
    vars.push_back({"R", {0x05, r}});
    vars.push_back({"S", {0x42, db.kdf.salt}});
  } else {
    vars.push_back({"$UUID", {0x42, unhex(db.kdf.type == K_ARGON2ID ? UUID_ARGON2ID : UUID_ARGON2D)}});
    Bytes it, mem, par, ver;
    add64(it, db.kdf.iterations);
    add64(mem, db.kdf.memory);
    add32(par, db.kdf.parallelism);
    add32(ver, db.kdf.version);
    vars.push_back({"S", {0x42, db.kdf.salt}});
    vars.push_back({"P", {0x04, par}});
    vars.push_back({"M", {0x05, mem}});
    vars.push_back({"I", {0x05, it}});
    vars.push_back({"V", {0x04, ver}});
  }
  Bytes h;
  add32(h, 0x9AA2D903);
  add32(h, 0xB54BFB67);
  h.push_back((uint8_t)db.minor);
  h.push_back((uint8_t)(db.minor >> 8));
  h.push_back((uint8_t)db.major);
  h.push_back((uint8_t)(db.major >> 8));
  auto field = [&](uint8_t id, const Bytes& v) {
    h.push_back(id);
    add32(h, (uint32_t)v.size());
    h.insert(h.end(), v.begin(), v.end());
  };
  field(2, unhex(db.cipher == C_AES ? UUID_AES : UUID_CHACHA));
  Bytes comp;
  add32(comp, db.compressed ? 1 : 0);
  field(3, comp);
  field(4, master_seed);
  field(7, iv);
  field(11, write_variants(vars));
  if (!db.public_custom.empty()) field(12, db.public_custom);
  field(0, Bytes{0x0D, 0x0A, 0x0D, 0x0A});
  Bytes transformed = transform_key(db.kdf, composite);
  Bytes key = sha256(cat(master_seed, transformed));
  Bytes mix = cat(master_seed, transformed);
  mix.push_back(1);
  Bytes hmac_key = sha512(mix);
  wipe(mix);
  wipe(transformed);
  auto block_key = [&](uint64_t index) {
    Bytes b;
    add64(b, index);
    b.insert(b.end(), hmac_key.begin(), hmac_key.end());
    return sha512(b);
  };
  // El contenido: el encabezado interno (ChaCha20 para los valores protegidos y los adjuntos) y el XML.
  Bytes inner_key = random_bytes(64);
  Bytes content;
  auto inner = [&](uint8_t id, const Bytes& v) {
    content.push_back(id);
    add32(content, (uint32_t)v.size());
    content.insert(content.end(), v.begin(), v.end());
  };
  Bytes sid;
  add32(sid, 3);
  inner(1, sid);
  inner(2, inner_key);
  for (size_t i = 0; i < db.binaries.size(); i++) {
    Bytes v;
    v.push_back(i < db.binary_flags.size() ? db.binary_flags[i] : 0);
    v.insert(v.end(), db.binaries[i].begin(), db.binaries[i].end());
    inner(3, v);
  }
  inner(0, Bytes());
  InnerStream st(3, inner_key);
  std::string xml = "<?xml version=\"1.0\" encoding=\"utf-8\" standalone=\"yes\"?>\n";
  protect(db.xml.get(), st, xml, 0);
  content.insert(content.end(), xml.begin(), xml.end());
  wipe(xml);
  wipe(inner_key);
  if (db.compressed) {
    Bytes z = gzip_stored(content);
    wipe(content);
    content.swap(z);
  }
  Bytes enc;
  if (db.cipher == C_AES) enc = aes_cbc_encrypt(key, iv, content);
  else {
    enc = content;
    ChaCha20 c(key.data(), iv.data());
    c.apply(enc.data(), enc.size());
  }
  wipe(content);
  wipe(key);
  out = h;
  Bytes hh = sha256(h);
  out.insert(out.end(), hh.begin(), hh.end());
  Bytes hm = hmac_sha256(block_key(0xFFFFFFFFFFFFFFFFull), h);
  out.insert(out.end(), hm.begin(), hm.end());
  // Bloques de 1 MiB con su HMAC; al final, uno vacío.
  size_t p = 0;
  for (uint64_t index = 0;; index++) {
    size_t sz = std::min<size_t>(1 << 20, enc.size() - p);
    Bytes msg;
    add64(msg, index);
    add32(msg, (uint32_t)sz);
    msg.insert(msg.end(), enc.begin() + (long)p, enc.begin() + (long)(p + sz));
    Bytes mac = hmac_sha256(block_key(index), msg);
    out.insert(out.end(), mac.begin(), mac.end());
    add32(out, (uint32_t)sz);
    out.insert(out.end(), enc.begin() + (long)p, enc.begin() + (long)(p + sz));
    p += sz;
    if (sz == 0) break;
  }
  wipe(hmac_key);
  return true;
}

// ============================================================ la base de datos por dentro
// Grupos y entradas son nodos del XML de KeePass: DMarlonPass los lee y los
// cambia ahí mismo, así que lo que no conoce (iconos, historial, datos de
// otros programas) se guarda tal cual.
std::string new_uuid() { return b64(random_bytes(16)); }
const std::string ZERO_UUID = "AAAAAAAAAAAAAAAAAAAAAA==";
long long unix_now() { return (long long)std::time(nullptr); }
Node* root_group(const Database& db) {
  Node* r = db.xml ? db.xml->child("Root") : nullptr;
  return r ? r->child("Group") : nullptr;
}
Node* meta(const Database& db) { return db.xml ? db.xml->child("Meta") : nullptr; }
void add_times(Node* n) {
  Node* t = n->ensure("Times");
  std::string now = kdbx_time(unix_now());
  t->set("CreationTime", now);
  t->set("LastModificationTime", now);
  t->set("LastAccessTime", now);
  t->set("ExpiryTime", now);
  t->set("Expires", "False");
  t->set("UsageCount", "0");
  t->set("LocationChanged", now);
}
void touch(Node* n) {
  Node* t = n->ensure("Times");
  std::string now = kdbx_time(unix_now());
  t->set("LastModificationTime", now);
  t->set("LastAccessTime", now);
}
Node* string_node(Node* entry, const std::string& key) {
  for (Node* s : entry->children("String"))
    if (s->get("Key") == key) return s;
  return nullptr;
}
std::string field(const Node* entry, const std::string& key) {
  for (Node* s : entry->children("String"))
    if (s->get("Key") == key) return s->get("Value");
  return "";
}
// Qué campos van protegidos (cifrados dentro del XML): lo dice Meta/MemoryProtection.
bool protected_key(const Database& db, const std::string& key) {
  Node* m = meta(db);
  Node* mp = m ? m->child("MemoryProtection") : nullptr;
  if (key == "Password") return !mp || mp->get("ProtectPassword") != "False";
  std::string name = key == "Title" ? "ProtectTitle" : key == "UserName" ? "ProtectUserName" : key == "URL" ? "ProtectURL" : key == "Notes" ? "ProtectNotes" : "";
  return mp && !name.empty() && mp->get(name) == "True";
}
void set_field(const Database& db, Node* entry, const std::string& key, const std::string& value) {
  Node* s = string_node(entry, key);
  if (!s) {
    // Los String van antes de AutoType y History (en el orden de KeePass).
    long at = -1;
    for (size_t i = 0; i < entry->kids.size(); i++)
      if (entry->kids[i]->name == "AutoType" || entry->kids[i]->name == "History") {
        at = (long)i;
        break;
      }
    std::unique_ptr<Node> n(new Node());
    n->name = "String";
    s = entry->adopt(std::move(n), at);
    s->add("Key", key);
    s->add("Value");
  }
  Node* v = s->ensure("Value");
  v->text = value;
  bool prot = protected_key(db, key) || v->attr("Protected") == "True";
  if (prot) v->set_attr("Protected", "True");
}
std::vector<Node*> groups(const Node* g) { return g->children("Group"); }
std::vector<Node*> entries(const Node* g) { return g->children("Entry"); }
bool is_recycle_bin(const Database& db, const Node* g) {
  Node* m = meta(db);
  std::string id = m ? m->get("RecycleBinUUID") : "";
  return !id.empty() && id != ZERO_UUID && g->get("UUID") == id;
}
Node* new_group(Node* parent, const std::string& name, int icon = 48) {
  // Antes de los subgrupos van las entradas; el grupo nuevo, al final.
  Node* g = parent->add("Group");
  g->add("UUID", new_uuid());
  g->add("Name", name);
  g->add("Notes");
  g->add("IconID", std::to_string(icon));
  add_times(g);
  g->add("IsExpanded", "True");
  g->add("DefaultAutoTypeSequence");
  g->add("EnableAutoType", "null");
  g->add("EnableSearching", "null");
  g->add("LastTopVisibleEntry", ZERO_UUID);
  return g;
}
Node* new_entry(const Database& db, Node* group) {
  // Las entradas van antes de los subgrupos (como las escribe KeePass).
  std::unique_ptr<Node> n(new Node());
  n->name = "Entry";
  long at = -1;
  for (size_t i = 0; i < group->kids.size(); i++)
    if (group->kids[i]->name == "Group") {
      at = (long)i;
      break;
    }
  Node* e = group->adopt(std::move(n), at);
  e->add("UUID", new_uuid());
  e->add("IconID", "0");
  e->add("ForegroundColor");
  e->add("BackgroundColor");
  e->add("OverrideURL");
  e->add("Tags");
  add_times(e);
  for (const char* k : {"Title", "UserName", "Password", "URL", "Notes"}) set_field(db, e, k, "");
  Node* at2 = e->add("AutoType");
  at2->add("Enabled", "True");
  at2->add("DataTransferObfuscation", "0");
  e->add("History");
  return e;
}
// Antes de cambiar una entrada, su versión de antes va al historial (como en KeePass).
void backup(const Database& db, Node* entry) {
  auto copy = entry->clone();
  Node* h = copy->child("History");
  if (h) copy->detach(h);
  Node* hist = entry->ensure("History");
  hist->adopt(std::move(copy));
  Node* m = meta(db);
  int max = m && !m->get("HistoryMaxItems").empty() ? std::atoi(m->get("HistoryMaxItems").c_str()) : 10;
  while (max >= 0 && (int)hist->kids.size() > max) hist->detach(hist->kids.front().get());
}
// Borrar: a la papelera (si está activada); desde la papelera, para siempre.
Node* recycle_bin(Database& db, bool create) {
  Node* m = meta(db);
  Node* root = root_group(db);
  if (!m || !root || m->get("RecycleBinEnabled") == "False") return nullptr;
  std::string id = m->get("RecycleBinUUID");
  std::function<Node*(Node*)> find = [&](Node* g) -> Node* {
    if (g->get("UUID") == id) return g;
    for (Node* k : groups(g))
      if (Node* r = find(k)) return r;
    return nullptr;
  };
  Node* bin = id.empty() || id == ZERO_UUID ? nullptr : find(root);
  if (!bin && create) {
    bin = new_group(root, tx::RECYCLE_BIN, 43);
    bin->set("EnableAutoType", "false");
    bin->set("EnableSearching", "false");
    m->set("RecycleBinUUID", bin->get("UUID"));
    m->set("RecycleBinChanged", kdbx_time(unix_now()));
  }
  return bin;
}
bool inside(const Node* n, const Node* ancestor) {
  for (const Node* p = n; p; p = p->parent)
    if (p == ancestor) return true;
  return false;
}
void forget(Database& db, Node* n) {
  Node* root = db.xml->child("Root");
  Node* del = root->ensure("DeletedObjects");
  Node* d = del->add("DeletedObject");
  d->add("UUID", n->get("UUID"));
  d->add("DeletionTime", kdbx_time(unix_now()));
}
void remove_node(Database& db, Node* n) {
  Node* bin = recycle_bin(db, true);
  Node* parent = n->parent;
  if (!parent) return;
  if (bin && !inside(n, bin) && n != bin) {
    auto moved = parent->detach(n);
    Node* t = moved->ensure("Times");
    t->set("LocationChanged", kdbx_time(unix_now()));
    if (moved->name == "Entry") {
      long at = -1;
      for (size_t i = 0; i < bin->kids.size(); i++)
        if (bin->kids[i]->name == "Group") {
          at = (long)i;
          break;
        }
      bin->adopt(std::move(moved), at);
    } else bin->adopt(std::move(moved));
    return;
  }
  forget(db, n);
  auto gone = parent->detach(n);
  gone->wipe_all();
}
// Una base de datos nueva, como la crea KeePass.
void new_database(Database& db, const std::string& name) {
  db = Database();
  db.kdf.type = K_ARGON2D;
  db.kdf.iterations = 10;
  db.kdf.memory = 64ull << 20;
  db.kdf.parallelism = 2;
  db.xml.reset(new Node());
  db.xml->name = "KeePassFile";
  std::string now = kdbx_time(unix_now());
  Node* m = db.xml->add("Meta");
  m->add("Generator", "DMarlonPass");
  m->add("DatabaseName", name);
  m->add("DatabaseNameChanged", now);
  m->add("DatabaseDescription");
  m->add("DatabaseDescriptionChanged", now);
  m->add("DefaultUserName");
  m->add("DefaultUserNameChanged", now);
  m->add("MaintenanceHistoryDays", "365");
  m->add("Color");
  m->add("MasterKeyChanged", now);
  m->add("MasterKeyChangeRec", "-1");
  m->add("MasterKeyChangeForce", "-1");
  Node* mp = m->add("MemoryProtection");
  mp->add("ProtectTitle", "False");
  mp->add("ProtectUserName", "False");
  mp->add("ProtectPassword", "True");
  mp->add("ProtectURL", "False");
  mp->add("ProtectNotes", "False");
  m->add("RecycleBinEnabled", "True");
  m->add("RecycleBinUUID", ZERO_UUID);
  m->add("RecycleBinChanged", now);
  m->add("EntryTemplatesGroup", ZERO_UUID);
  m->add("EntryTemplatesGroupChanged", now);
  m->add("HistoryMaxItems", "10");
  m->add("HistoryMaxSize", "6291456");
  m->add("LastSelectedGroup", ZERO_UUID);
  m->add("LastTopVisibleGroup", ZERO_UUID);
  m->add("SettingsChanged", now);
  Node* root = db.xml->add("Root");
  Node* g = new_group(root, name, 49);
  (void)g;
  root->add("DeletedObjects");
}

// ============================================================ fuerza, generador y revisión
// Cuánto cuesta adivinar una contraseña, en bits: el tamaño del alfabeto que
// usa por su longitud, con descuentos por lo que se adivina fácil (las
// contraseñas de siempre, letras repetidas, secuencias como «1234» o «abcd»).
struct Strength {
  double bits = 0;
  int level = 0;   // 0 muy débil, 1 débil, 2 aceptable, 3 fuerte, 4 muy fuerte
};
bool common_password(const std::string& p) {
  static const char* list[] = {"123456", "password", "123456789", "12345678", "12345", "qwerty", "1234567", "111111", "1234567890",
                               "123123", "abc123", "1234", "password1", "iloveyou", "1q2w3e4r", "000000", "qwerty123", "zaq12wsx",
                               "dragon", "sunshine", "princess", "letmein", "654321", "monkey", "27653", "1qaz2wsx", "123321", "qwertyuiop",
                               "superman", "asdfghjkl", "contraseña", "contrasena", "admin", "welcome", "football", "master", "hola123",
                               "teamo", "123qwe", "qwe123", "passw0rd", "secret", "secreto", "clave", "clave123", "barcelona", "realmadrid"};
  std::string l;
  for (char c : p) l += (char)std::tolower((unsigned char)c);
  for (const char* w : list)
    if (l == w) return true;
  return false;
}
Strength strength(const std::string& p) {
  Strength s;
  if (p.empty()) return s;
  bool lo = false, up = false, dg = false, sy = false, other = false;
  size_t chars = 0;
  for (size_t i = 0; i < p.size(); i++) {
    unsigned char c = (unsigned char)p[i];
    if ((c & 0xC0) == 0x80) continue;
    chars++;
    if (c >= 'a' && c <= 'z') lo = true;
    else if (c >= 'A' && c <= 'Z') up = true;
    else if (c >= '0' && c <= '9') dg = true;
    else if (c < 0x80) sy = true;
    else other = true;
  }
  double pool = (lo ? 26 : 0) + (up ? 26 : 0) + (dg ? 10 : 0) + (sy ? 33 : 0) + (other ? 100 : 0);
  // Lo que se repite o va en secuencia cuenta menos.
  double effective = 0;
  for (size_t i = 0; i < p.size(); i++) {
    unsigned char c = (unsigned char)p[i];
    if ((c & 0xC0) == 0x80) continue;
    bool rep = i > 0 && p[i] == p[i - 1];
    bool seq = i > 0 && (c == (unsigned char)p[i - 1] + 1 || c + 1 == (unsigned char)p[i - 1]) && c < 0x80;
    effective += rep ? 0.25 : seq ? 0.5 : 1.0;
  }
  s.bits = effective * std::log2(std::max(2.0, pool));
  if (common_password(p)) s.bits = std::min(s.bits, 10.0);
  (void)chars;
  s.level = s.bits < 36 ? 0 : s.bits < 60 ? 1 : s.bits < 80 ? 2 : s.bits < 110 ? 3 : 4;
  return s;
}
// El generador: con el azar del sistema, al menos un carácter de cada tipo elegido.
struct GenOptions {
  int length = 20;
  bool upper = true, lower = true, digits = true, symbols = true, no_ambiguous = true;
};
std::string generate(const GenOptions& o) {
  std::string sets[4] = {o.upper ? "ABCDEFGHIJKLMNOPQRSTUVWXYZ" : "", o.lower ? "abcdefghijklmnopqrstuvwxyz" : "", o.digits ? "0123456789" : "",
                         o.symbols ? "!#$%&*+-=?@^_~.,:;()[]{}" : ""};
  if (o.no_ambiguous)
    for (auto& s : sets) {
      std::string t;
      for (char c : s)
        if (std::string("Il1O0o|`'\"").find(c) == std::string::npos) t += c;
      s = t;
    }
  std::string all;
  std::vector<std::string> used;
  for (const auto& s : sets)
    if (!s.empty()) {
      all += s;
      used.push_back(s);
    }
  if (all.empty()) return "";
  int len = std::max((int)used.size(), std::min(128, o.length));
  std::string out;
  for (const auto& s : used) out += s[kp::random_below((uint32_t)s.size())];
  while ((int)out.size() < len) out += all[kp::random_below((uint32_t)all.size())];
  // Barajar (Fisher-Yates) para que los obligatorios no queden al principio.
  for (int i = (int)out.size() - 1; i > 0; i--) std::swap(out[(size_t)i], out[kp::random_below((uint32_t)i + 1)]);
  return out;
}
// Lo que vale una contraseña generada: el largo por los bits de su alfabeto.
double generated_bits(const GenOptions& o) {
  int pool = (o.upper ? 26 : 0) + (o.lower ? 26 : 0) + (o.digits ? 10 : 0) + (o.symbols ? 24 : 0);
  if (o.no_ambiguous) pool -= (o.upper ? 2 : 0) + (o.lower ? 2 : 0) + (o.digits ? 2 : 0);
  return pool > 1 ? o.length * std::log2((double)pool) : 0;
}
// La revisión de seguridad: lo débil, lo repetido, lo vacío y lo que lleva años sin cambiar.
enum Issue { I_WEAK = 1, I_REUSED = 2, I_EMPTY = 4, I_OLD = 8 };
struct Finding {
  Node* entry;
  int issues = 0;
  int reused = 0;   // cuántas entradas comparten la contraseña
};
void collect(const Database& db, Node* g, std::vector<Node*>& out) {
  if (is_recycle_bin(db, g)) return;
  for (Node* e : entries(g)) out.push_back(e);
  for (Node* k : groups(g)) collect(db, k, out);
}
std::vector<Finding> audit(const Database& db, long long now) {
  std::vector<Node*> all;
  if (Node* r = root_group(db)) collect(db, r, all);
  std::map<std::string, int> count;
  for (Node* e : all) {
    std::string p = field(e, "Password");
    if (!p.empty()) count[hex(sha256(bytes(p)))]++;   // se cuentan por su huella, no por el texto
  }
  std::vector<Finding> out;
  for (Node* e : all) {
    std::string p = field(e, "Password");
    Finding f;
    f.entry = e;
    if (p.empty()) f.issues |= I_EMPTY;
    else {
      if (strength(p).level <= 1) f.issues |= I_WEAK;
      int c = count[hex(sha256(bytes(p)))];
      if (c > 1) {
        f.issues |= I_REUSED;
        f.reused = c;
      }
    }
    Node* t = e->child("Times");
    long long mod = t ? parse_time(t->get("LastModificationTime")) : 0;
    if (mod > 0 && now - mod > 365LL * 86400) f.issues |= I_OLD;
    if (f.issues) out.push_back(f);
  }
  // Primero lo más grave: vacías, débiles y repetidas.
  std::stable_sort(out.begin(), out.end(), [](const Finding& a, const Finding& b) {
    auto w = [](int i) { return (i & I_EMPTY ? 8 : 0) + (i & I_WEAK ? 4 : 0) + (i & I_REUSED ? 2 : 0) + (i & I_OLD ? 1 : 0); };
    return w(a.issues) > w(b.issues);
  });
  return out;
}
// Calibrar Argon2: cuántas pasadas caben en el tiempo de apertura elegido.
uint64_t calibrate_argon2(KdfType type, uint64_t memory, uint32_t par, double target_ms) {
  auto t0 = std::chrono::steady_clock::now();
  argon2(type == K_ARGON2ID ? ARGON2_ID : ARGON2_D, Bytes(32, 1), Bytes(32, 2), 1, (uint32_t)(memory / 1024), par, 32);
  double one = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
  return (uint64_t)std::max(2.0, std::min(1000.0, std::floor(target_ms / std::max(1.0, one))));
}
uint64_t calibrate_aeskdf(double target_ms) {
  Bytes k(32, 1);
  Aes256 a(Bytes(32, 2).data());
  auto t0 = std::chrono::steady_clock::now();
  for (int i = 0; i < 100000; i++) a.encrypt(k.data(), k.data());
  double ms = std::chrono::duration<double, std::milli>(std::chrono::steady_clock::now() - t0).count();
  return (uint64_t)std::max(60000.0, target_ms / std::max(0.001, ms) * 100000 / 2);
}

// ============================================================ el dibujo
Fl_Color rgb(unsigned v) { return fl_rgb_color((uchar)(v >> 16), (uchar)(v >> 8), (uchar)v); }
const unsigned C_SIDE = 0x1c2233, C_SIDE_SEL = 0x2e3a57, C_SIDE_TEXT = 0xe7eaf3, C_SIDE_MUTED = 0x8d95ab, C_BG = 0xf5f6fa, C_CARD = 0xffffff,
               C_LINE = 0xe2e5ee, C_TEXT = 0x1d2233, C_MUTED = 0x697089, C_ACCENT = 0x3b6cf6, C_ACCENT_D = 0x2a52c9, C_SOFT = 0xe9effe,
               C_GOOD = 0x1f9d55, C_WARN = 0xe08a00, C_BAD = 0xe5484d;
const unsigned LEVEL_COLORS[] = {0xe5484d, 0xf0712a, 0xe0b100, 0x45b36b, 0x1f9d55};
const char* level_name(int l) {
  static const char* n[] = {tx::S_VERY_WEAK, tx::S_WEAK, tx::S_FAIR, tx::S_STRONG, tx::S_VERY_STRONG};
  return n[std::max(0, std::min(4, l))];
}
struct Hit {
  int x, y, w, h, act, idx;
};
void round_box(int x, int y, int w, int h, int r, Fl_Color fill, Fl_Color line) {
  fl_color(line);
  fl_rounded_rectf(x, y, w, h, r);
  fl_color(fill);
  fl_rounded_rectf(x + 1, y + 1, w - 2, h - 2, std::max(0, r - 1));
}
std::string fit(const std::string& s, int w) {
  if ((int)fl_width(s.c_str()) <= w) return s;
  std::string t = s;
  while (!t.empty() && (int)fl_width((t + "…").c_str()) > w) {
    t.pop_back();
    while (!t.empty() && ((unsigned char)t.back() & 0xC0) == 0x80) t.pop_back();
  }
  return t + "…";
}
std::vector<std::string> wrap(const std::string& s, int w) {
  std::vector<std::string> out;
  size_t a = 0;
  while (true) {
    size_t b = s.find('\n', a);
    std::string para = s.substr(a, b == std::string::npos ? std::string::npos : b - a);
    std::string line;
    size_t i = 0;
    while (i <= para.size()) {
      size_t sp = para.find(' ', i);
      std::string word = para.substr(i, sp == std::string::npos ? std::string::npos : sp - i);
      std::string t = line.empty() ? word : line + " " + word;
      if (!line.empty() && (int)fl_width(t.c_str()) > w) {
        out.push_back(line);
        line = word;
      } else line = t;
      if (sp == std::string::npos) break;
      i = sp + 1;
    }
    out.push_back(fit(line, w));
    if (b == std::string::npos) break;
    a = b + 1;
  }
  return out;
}
std::string date_text(long long t) {
  if (t <= 0) return "—";
  std::time_t tt = (std::time_t)t;
  std::tm v{};
#ifdef _WIN32
  localtime_s(&v, &tt);
#else
  localtime_r(&tt, &v);
#endif
  char b[32];
  std::strftime(b, sizeof b, "%d/%m/%Y %H:%M", &v);
  return b;
}
// El escudo de DMarlonPass, con su cerradura.
void shield(int cx, int cy, int s, unsigned color) {
  fl_color(rgb(color));
  fl_begin_polygon();
  fl_vertex(cx - s, cy - s * 0.8);
  fl_vertex(cx, cy - s * 1.1);
  fl_vertex(cx + s, cy - s * 0.8);
  fl_vertex(cx + s * 0.9, cy + s * 0.2);
  fl_vertex(cx, cy + s * 1.15);
  fl_vertex(cx - s * 0.9, cy + s * 0.2);
  fl_end_polygon();
  fl_color(FL_WHITE);
  int r = std::max(3, s / 4);
  fl_pie(cx - r, cy - r - s / 5, 2 * r, 2 * r, 0, 360);
  fl_begin_polygon();
  fl_vertex(cx - r / 2, cy - s / 5);
  fl_vertex(cx + r / 2, cy - s / 5);
  fl_vertex(cx + r * 0.8, cy + s / 2);
  fl_vertex(cx - r * 0.8, cy + s / 2);
  fl_end_polygon();
}
unsigned avatar_color(const std::string& s) {
  static const unsigned c[] = {0x3b6cf6, 0x8b5cf6, 0x0ea5e9, 0x14b8a6, 0x22c55e, 0xf59e0b, 0xef4444, 0xec4899, 0x6366f1, 0x64748b};
  uint32_t h = 2166136261u;
  for (unsigned char ch : s) h = (h ^ ch) * 16777619u;
  return c[h % 10];
}
std::string initial(const std::string& s) {
  if (s.empty()) return "?";
  size_t n = 1;
  while (n < s.size() && ((unsigned char)s[n] & 0xC0) == 0x80) n++;
  std::string i = s.substr(0, n);
  if (i.size() == 1) i[0] = (char)std::toupper((unsigned char)i[0]);
  return i;
}
// Puntos en lugar de la contraseña (como mucho 16: no dice cuánto mide).
std::string mask(const std::string& p) {
  size_t n = 0;
  for (unsigned char c : p) n += (c & 0xC0) != 0x80;
  std::string o;
  for (size_t i = 0; i < std::min<size_t>(n, 16); i++) o += "•";
  return o;
}

enum Mode { M_WELCOME = 0, M_LOCKED, M_VAULT };
struct GroupRow {
  Node* g;
  int depth, count;
  bool bin;
};
class VaultView : public Fl_Widget {
public:
  Mode mode = M_WELCOME;
  // Bloqueo y bienvenida.
  std::string file_name, key_file_name, error;
  bool busy = false;
  // La bóveda.
  std::vector<GroupRow> rows;
  int group = 0;                  // la fila elegida (-1: la revisión de seguridad)
  std::vector<Node*> list;        // las entradas que se ven
  std::vector<Finding> findings;  // en la revisión, por qué sale cada una
  int selected = -1, list_scroll = 0, list_h = 0, hover = -1;
  bool show_password = false, searching = false, auditing = false;
  int audit_count = 0;
  std::string group_path;
  long long now = 0;
  std::vector<Hit> hits;
  std::function<void(int, int)> on_act;
  std::function<void(int, int)> on_context;   // clic derecho: (qué, índice)
  std::function<bool(int)> on_key;
  // Dónde van la contraseña maestra y el botón (los coloca la ventana).
  int master_y = 0;
  VaultView(int X, int Y, int W, int H) : Fl_Widget(X, Y, W, H) {}
  void repaint() {
    if (parent()) parent()->redraw();
    else redraw();
  }
  void button(int bx, int by, int bw, int bh, const std::string& label, int act, int idx, unsigned fill, unsigned fg, unsigned line,
              int size = 14) {
    bool hot = (int)hits.size() == hover;
    round_box(bx, by, bw, bh, 9, rgb(hot && fill == C_CARD ? 0xf3f5fb : fill), rgb(line));
    fl_font(FL_HELVETICA_BOLD, size);
    fl_color(rgb(fg));
    fl_draw(fit(label, bw - 10).c_str(), bx, by, bw, bh, FL_ALIGN_CENTER);
    hits.push_back({bx, by, bw, bh, act, idx});
  }
  void link(int lx, int ly, const std::string& label, int act) {
    fl_font(FL_HELVETICA, 13);
    int lw = (int)fl_width(label.c_str());
    bool hot = (int)hits.size() == hover;
    fl_color(rgb(hot ? C_ACCENT_D : C_ACCENT));
    fl_draw(label.c_str(), lx, ly + 15);
    if (hot) fl_line(lx, ly + 18, lx + lw, ly + 18);
    hits.push_back({lx, ly, lw, 20, act, -1});
  }

  // ---- bienvenida y bloqueo
  void draw_gate() {
    fl_color(rgb(C_SIDE));
    fl_rectf(x(), y(), w(), h());
    // Un fondo con un poco de luz.
    for (int i = 0; i < 6; i++) {
      fl_color(fl_rgb_color((uchar)(0x1c + i * 3), (uchar)(0x22 + i * 3), (uchar)(0x33 + i * 5)));
      fl_pie(x() + w() / 2 - 420 + i * 40, y() - 300 + i * 30, 840 - i * 80, 840 - i * 80, 0, 360);
    }
    int cw = 440, ch = mode == M_LOCKED ? 400 : 360;
    int cx = x() + (w() - cw) / 2, cy = y() + std::max(20, (h() - ch) / 2);
    round_box(cx, cy, cw, ch, 20, rgb(C_CARD), rgb(C_LINE));
    shield(cx + cw / 2, cy + 58, 26, C_ACCENT);
    fl_font(FL_HELVETICA_BOLD, 24);
    fl_color(rgb(C_TEXT));
    fl_draw("DMarlonPass", cx, cy + 96, cw, 34, FL_ALIGN_CENTER);
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(C_MUTED));
    if (mode == M_WELCOME) {
      fl_draw(tx::WELCOME_SUB, cx + 30, cy + 132, cw - 60, 40, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
      button(cx + 40, cy + 190, cw - 80, 46, tx::CREATE_DB, 1, -1, C_ACCENT, 0xffffff, C_ACCENT_D, 15);
      button(cx + 40, cy + 248, cw - 80, 46, tx::OPEN_DB, 2, -1, C_CARD, C_TEXT, C_LINE, 15);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(C_MUTED));
      fl_draw(tx::COMPAT_NOTE, cx + 30, cy + 306, cw - 60, 40, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
      master_y = 0;
      return;
    }
    // Bloqueada: el archivo, la contraseña maestra y, si hace falta, el archivo de clave.
    fl_draw(("🗄  " + fit(file_name, cw - 80)).c_str(), cx, cy + 132, cw, 20, FL_ALIGN_CENTER);
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(rgb(C_TEXT));
    fl_draw(tx::MASTER_LABEL, cx + 40, cy + 178);
    master_y = cy + 186;   // aquí va el campo (Master) y debajo el botón (BtnUnlock)
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(C_MUTED));
    std::string kf = key_file_name.empty() ? std::string(tx::NO_KEY_FILE) : "🔑 " + key_file_name;
    fl_draw(fit(kf, cw - 200).c_str(), cx + 40, cy + 254);
    link(cx + cw - 40 - (int)fl_width(key_file_name.empty() ? tx::CHOOSE_KEY_FILE : tx::REMOVE_KEY_FILE),
         cy + 239, key_file_name.empty() ? tx::CHOOSE_KEY_FILE : tx::REMOVE_KEY_FILE, key_file_name.empty() ? 3 : 4);
    if (!error.empty()) {
      fl_font(FL_HELVETICA_BOLD, 13);
      fl_color(rgb(C_BAD));
      fl_draw(error.c_str(), cx + 30, cy + 316, cw - 60, 20, FL_ALIGN_CENTER);
    } else if (busy) {
      fl_font(FL_HELVETICA, 13);
      fl_color(rgb(C_MUTED));
      fl_draw(tx::OPENING, cx + 30, cy + 316, cw - 60, 20, FL_ALIGN_CENTER);
    }
    link(cx + 40, cy + ch - 46, tx::OTHER_DB, 5);
    fl_font(FL_HELVETICA, 13);
    link(cx + cw - 40 - (int)fl_width(tx::NEW_DB_LINK), cy + ch - 46, tx::NEW_DB_LINK, 1);
  }

  // ---- la bóveda: grupos, entradas y la entrada elegida
  const int side_w = 240, detail_w = 380;
  void draw_side() {
    fl_color(rgb(C_SIDE));
    fl_rectf(x(), y(), side_w, h());
    fl_font(FL_HELVETICA_BOLD, 11);
    fl_color(rgb(C_SIDE_MUTED));
    fl_draw(tx::GROUPS, x() + 18, y() + 26);
    int Y = y() + 38;
    for (int i = 0; i < (int)rows.size(); i++) {
      const GroupRow& r = rows[(size_t)i];
      bool sel = !auditing && i == group && !searching;
      bool hot = (int)hits.size() == hover;
      if (sel || hot) {
        fl_color(rgb(sel ? C_SIDE_SEL : 0x252c40));
        fl_rounded_rectf(x() + 8, Y, side_w - 16, 32, 8);
      }
      int ix = x() + 18 + r.depth * 16;
      fl_font(FL_HELVETICA, 14);
      fl_draw(r.bin ? "🗑" : r.depth == 0 ? "🗄" : "📁", ix, Y, 22, 32, FL_ALIGN_CENTER);
      fl_color(rgb(sel ? 0xffffff : C_SIDE_TEXT));
      fl_font(sel ? FL_HELVETICA_BOLD : FL_HELVETICA, 14);
      std::string cnt = std::to_string(r.count);
      int cntw = (int)fl_width(cnt.c_str());
      fl_draw(fit(r.g->get("Name"), side_w - (ix - x()) - 50 - cntw).c_str(), ix + 28, Y + 21);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(C_SIDE_MUTED));
      fl_draw(cnt.c_str(), x() + side_w - 22 - cntw, Y + 21);
      hits.push_back({x() + 8, Y, side_w - 16, 32, 10, i});
      Y += 34;
      if (Y > y() + h() - 90) break;
    }
    // Abajo: la revisión de seguridad.
    int by = y() + h() - 64;
    bool sel = auditing;
    bool hot = (int)hits.size() == hover;
    fl_color(rgb(sel ? C_SIDE_SEL : hot ? 0x252c40 : C_SIDE));
    fl_rounded_rectf(x() + 8, by, side_w - 16, 48, 10);
    fl_font(FL_HELVETICA, 16);
    fl_draw("🛡", x() + 18, by, 24, 48, FL_ALIGN_CENTER);
    fl_font(FL_HELVETICA_BOLD, 13);
    fl_color(rgb(C_SIDE_TEXT));
    fl_draw(tx::AUDIT, x() + 50, by + 21);
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(audit_count ? 0xffb347 : 0x7fd49a));
    fl_draw(audit_count ? fmt(tx::AUDIT_N, {std::to_string(audit_count)}).c_str() : tx::AUDIT_OK, x() + 50, by + 38);
    hits.push_back({x() + 8, by, side_w - 16, 48, 11, -1});
  }
  std::string reason_text(const Finding& f) const {
    std::string o;
    auto add = [&](const std::string& s) { o += (o.empty() ? "" : " · ") + s; };
    if (f.issues & I_EMPTY) add(tx::I_EMPTY_T);
    if (f.issues & I_WEAK) add(tx::I_WEAK_T);
    if (f.issues & I_REUSED) add(fmt(tx::I_REUSED_T, {std::to_string(f.reused)}));
    if (f.issues & I_OLD) add(tx::I_OLD_T);
    return o;
  }
  void draw_list() {
    int lx = x() + side_w, lw = w() - side_w - detail_w;
    fl_color(rgb(C_CARD));
    fl_rectf(lx, y(), lw, h());
    fl_color(rgb(C_LINE));
    fl_line(lx + lw - 1, y(), lx + lw - 1, y() + h());
    // El título de la lista.
    fl_font(FL_HELVETICA_BOLD, 16);
    fl_color(rgb(C_TEXT));
    std::string title = auditing ? tx::AUDIT : searching ? tx::SEARCH_RESULTS : group_path;
    fl_draw(fit(title, lw - 40).c_str(), lx + 18, y() + 30);
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(C_MUTED));
    fl_draw(fmt(list.size() == 1 ? tx::ENTRIES_ONE : tx::ENTRIES_N, {std::to_string(list.size())}).c_str(), lx + 18, y() + 50);
    fl_color(rgb(C_LINE));
    fl_line(lx, y() + 62, lx + lw, y() + 62);
    fl_push_clip(lx, y() + 63, lw - 1, h() - 63);
    const int rh = auditing ? 70 : 60;
    list_h = (int)list.size() * rh;
    list_scroll = std::max(0, std::min(list_scroll, std::max(0, list_h - (h() - 63))));
    int Y = y() + 63 - list_scroll;
    for (int i = 0; i < (int)list.size(); i++, Y += rh) {
      if (Y + rh < y() + 63 || Y > y() + h()) continue;
      Node* e = list[(size_t)i];
      bool sel = i == selected, hot = (int)hits.size() == hover;
      fl_color(rgb(sel ? C_SOFT : hot ? 0xf7f8fc : C_CARD));
      fl_rectf(lx, Y, lw - 1, rh);
      if (sel) {
        fl_color(rgb(C_ACCENT));
        fl_rectf(lx, Y, 3, rh);
      }
      std::string t = field(e, "Title");
      fl_color(rgb(avatar_color(t)));
      fl_pie(lx + 16, Y + 12, 36, 36, 0, 360);
      fl_font(FL_HELVETICA_BOLD, 16);
      fl_color(FL_WHITE);
      fl_draw(initial(t).c_str(), lx + 16, Y + 12, 36, 36, FL_ALIGN_CENTER);
      fl_font(FL_HELVETICA_BOLD, 14);
      fl_color(rgb(C_TEXT));
      fl_draw(fit(t.empty() ? tx::NO_TITLE : t, lw - 90).c_str(), lx + 64, Y + 26);
      fl_font(FL_HELVETICA, 12);
      fl_color(rgb(C_MUTED));
      fl_draw(fit(field(e, "UserName"), lw - 90).c_str(), lx + 64, Y + 44);
      if (auditing && i < (int)findings.size()) {
        fl_font(FL_HELVETICA_BOLD, 11);
        fl_color(rgb(findings[(size_t)i].issues & (I_EMPTY | I_WEAK) ? C_BAD : C_WARN));
        fl_draw(fit(reason_text(findings[(size_t)i]), lw - 90).c_str(), lx + 64, Y + 60);
      }
      fl_color(rgb(C_LINE));
      fl_line(lx + 64, Y + rh - 1, lx + lw, Y + rh - 1);
      hits.push_back({lx, Y, lw - 1, rh, 20, i});
    }
    if (list.empty()) {
      fl_font(FL_HELVETICA, 14);
      fl_color(rgb(C_MUTED));
      fl_draw(auditing ? tx::AUDIT_EMPTY : searching ? tx::SEARCH_EMPTY : tx::GROUP_EMPTY, lx + 24, y() + 110, lw - 48, 60,
              FL_ALIGN_CENTER | FL_ALIGN_WRAP);
      if (!auditing && !searching) button(lx + (lw - 180) / 2, y() + 180, 180, 40, tx::ADD_ENTRY_BTN, 40, -1, C_ACCENT, 0xffffff, C_ACCENT_D);
    }
    fl_pop_clip();
  }
  void field_row(int fx, int& fy, int fw, const char* label, const std::string& value, bool secret, int copy_act) {
    fl_font(FL_HELVETICA_BOLD, 11);
    fl_color(rgb(C_MUTED));
    fl_draw(label, fx, fy + 12);
    fl_font(secret && !show_password ? FL_HELVETICA_BOLD : FL_HELVETICA, 15);
    fl_color(rgb(value.empty() ? C_MUTED : C_TEXT));
    std::string shown = value.empty() ? "—" : secret && !show_password ? mask(value) : value;
    int buttons = copy_act ? (secret ? 2 : copy_act == 34 ? 2 : 1) : 0;
    fl_draw(fit(shown, fw - buttons * 40 - 8).c_str(), fx, fy + 36);
    int bx = fx + fw - 34;
    if (copy_act && !value.empty()) {
      button(bx, fy + 16, 34, 30, "⧉", copy_act, -1, C_CARD, C_ACCENT, C_LINE, 15);
      bx -= 40;
      if (secret) button(bx, fy + 16, 34, 30, show_password ? "🙈" : "👁", 32, -1, C_CARD, C_ACCENT, C_LINE, 14);
      if (copy_act == 34) button(bx, fy + 16, 34, 30, "↗", 33, -1, C_CARD, C_ACCENT, C_LINE, 15);
    }
    fl_color(rgb(C_LINE));
    fl_line(fx, fy + 52, fx + fw, fy + 52);
    fy += 62;
  }
  void draw_detail() {
    int dx = x() + w() - detail_w;
    fl_color(rgb(C_BG));
    fl_rectf(dx, y(), detail_w, h());
    if (selected < 0 || selected >= (int)list.size()) {
      shield(dx + detail_w / 2, y() + h() / 2 - 40, 30, 0xd6dbe8);
      fl_font(FL_HELVETICA, 14);
      fl_color(rgb(C_MUTED));
      fl_draw(tx::PICK_ENTRY, dx + 30, y() + h() / 2 + 10, detail_w - 60, 40, FL_ALIGN_CENTER | FL_ALIGN_WRAP);
      return;
    }
    Node* e = list[(size_t)selected];
    int fx = dx + 24, fw = detail_w - 48, fy = y() + 22;
    std::string t = field(e, "Title");
    fl_color(rgb(avatar_color(t)));
    fl_pie(fx, fy, 48, 48, 0, 360);
    fl_font(FL_HELVETICA_BOLD, 22);
    fl_color(FL_WHITE);
    fl_draw(initial(t).c_str(), fx, fy, 48, 48, FL_ALIGN_CENTER);
    fl_font(FL_HELVETICA_BOLD, 19);
    fl_color(rgb(C_TEXT));
    fl_draw(fit(t.empty() ? tx::NO_TITLE : t, fw - 64).c_str(), fx + 62, fy + 22);
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(C_MUTED));
    std::string where;
    for (Node* p = e->parent; p && p->name == "Group"; p = p->parent) where = p->get("Name") + (where.empty() ? "" : " › " + where);
    fl_draw(fit(where, fw - 64).c_str(), fx + 62, fy + 42);
    fy += 70;
    field_row(fx, fy, fw, tx::F_USER, field(e, "UserName"), false, 30);
    std::string pw = field(e, "Password");
    field_row(fx, fy, fw, tx::F_PASSWORD, pw, true, 31);
    if (!pw.empty()) {
      // La fuerza, en una barra.
      Strength st = strength(pw);
      fy -= 8;
      for (int k = 0; k < 5; k++) {
        fl_color(rgb(k <= st.level ? LEVEL_COLORS[st.level] : C_LINE));
        fl_rounded_rectf(fx + k * 38, fy, 34, 5, 2);
      }
      fl_font(FL_HELVETICA, 11);
      fl_color(rgb(LEVEL_COLORS[st.level]));
      fl_draw(fmt(tx::STRENGTH_T, {level_name(st.level), std::to_string((int)st.bits)}).c_str(), fx + 200, fy + 7);
      fy += 18;
    }
    field_row(fx, fy, fw, tx::F_URL, field(e, "URL"), false, 34);
    // Las notas.
    fl_font(FL_HELVETICA_BOLD, 11);
    fl_color(rgb(C_MUTED));
    fl_draw(tx::F_NOTES, fx, fy + 12);
    fl_font(FL_HELVETICA, 13);
    fl_color(rgb(C_TEXT));
    std::string notes = field(e, "Notes");
    int ny = fy + 32;
    for (const auto& l : wrap(notes.empty() ? "—" : notes, fw)) {
      if (ny > y() + h() - 120) break;
      fl_draw(l.c_str(), fx, ny);
      ny += 18;
    }
    // Abajo: las fechas y los botones.
    Node* tm = e->child("Times");
    Node* hist = e->child("History");
    fl_font(FL_HELVETICA, 11);
    fl_color(rgb(C_MUTED));
    std::string dates = fmt(tx::DATES, {date_text(tm ? parse_time(tm->get("CreationTime")) : 0), date_text(tm ? parse_time(tm->get("LastModificationTime")) : 0)});
    if (hist && !hist->kids.empty()) dates += " · " + fmt(tx::HISTORY_N, {std::to_string(hist->kids.size())});
    fl_draw(fit(dates, fw).c_str(), fx, y() + h() - 70);
    button(fx, y() + h() - 56, (fw - 12) / 2, 40, tx::EDIT_BTN, 35, -1, C_ACCENT, 0xffffff, C_ACCENT_D);
    button(fx + (fw - 12) / 2 + 12, y() + h() - 56, (fw - 12) / 2, 40, tx::DELETE_BTN, 36, -1, C_CARD, C_BAD, C_LINE);
  }
  void draw() override {
    hits.clear();
    fl_push_clip(x(), y(), w(), h());
    if (mode != M_VAULT) draw_gate();
    else {
      draw_side();
      draw_list();
      draw_detail();
    }
    fl_pop_clip();
  }
  int hit_at(int ex, int ey) const {
    for (int i = (int)hits.size() - 1; i >= 0; i--) {
      const Hit& h = hits[(size_t)i];
      if (h.act && ex >= h.x && ex < h.x + h.w && ey >= h.y && ey < h.y + h.h) return i;
    }
    return -1;
  }
  int handle(int e) override {
    switch (e) {
      case FL_ENTER: return 1;
      case FL_MOVE: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i != hover) {
          hover = i;
          repaint();
        }
        if (window()) window()->cursor(i >= 0 ? FL_CURSOR_HAND : FL_CURSOR_DEFAULT);
        return 1;
      }
      case FL_LEAVE:
        hover = -1;
        if (window()) window()->cursor(FL_CURSOR_DEFAULT);
        repaint();
        return 1;
      case FL_PUSH: {
        int i = hit_at(Fl::event_x(), Fl::event_y());
        if (i < 0) return 1;
        const Hit& h = hits[(size_t)i];
        if (Fl::event_button() == FL_RIGHT_MOUSE) {
          if (on_context && (h.act == 10 || h.act == 20)) on_context(h.act, h.idx);
          return 1;
        }
        if (Fl::visible_focus() && mode == M_VAULT) Fl::focus(this);
        if (on_act) on_act(h.act, h.idx);
        // Doble clic en una entrada: editarla.
        if (h.act == 20 && Fl::event_clicks() > 0 && on_act) on_act(35, -1);
        return 1;
      }
      case FL_FOCUS:
      case FL_UNFOCUS:
        return 1;
      case FL_KEYBOARD:
        return on_key && on_key(Fl::event_key()) ? 1 : 0;
      case FL_MOUSEWHEEL:
        if (mode == M_VAULT && Fl::event_x() > x() + side_w && Fl::event_x() < x() + w() - detail_w) {
          list_scroll = std::max(0, std::min(list_scroll + Fl::event_dy() * 40, std::max(0, list_h - (h() - 63))));
          repaint();
        }
        return 1;
    }
    return Fl_Widget::handle(e);
  }
};

// ============================================================ las ventanas de diálogo
// Se arman con código (como las del sistema): la entrada, el generador, la base
// de datos nueva, la clave maestra y la seguridad. Con «shot» se dibujan en un
// PNG sin enseñarse (para las capturas de la web).
std::string& dialog_shot() {
  static std::string s;
  return s;
}
bool shoot(Fl_Window& win) {
  if (dialog_shot().empty()) return false;
  Fl_Image_Surface surf(win.w(), win.h(), 0);
  Fl_Surface_Device::push_current(&surf);
  fl_color(win.color());
  fl_rectf(0, 0, win.w(), win.h());
  for (int i = 0; i < win.children(); i++) surf.draw(win.child(i), win.child(i)->x(), win.child(i)->y());
  Fl_RGB_Image* img = surf.image();
  Fl_Surface_Device::pop_current();
  fl_write_png(dialog_shot().c_str(), img);
  delete img;
  return true;
}
// La barra de fuerza (se pinta según lo que haya en el campo).
class StrengthBar : public Fl_Box {
public:
  Fl_Input* source = nullptr;
  StrengthBar(int X, int Y, int W, int H) : Fl_Box(X, Y, W, H) {}
  void draw() override {
    std::string p = source && source->value() ? source->value() : "";
    Strength s = strength(p);
    int segw = (w() - 4 * 6) / 5;
    for (int k = 0; k < 5; k++) {
      fl_color(rgb(!p.empty() && k <= s.level ? LEVEL_COLORS[s.level] : C_LINE));
      fl_rounded_rectf(x() + k * (segw + 6), y(), segw, 6, 3);
    }
    fl_font(FL_HELVETICA, 12);
    fl_color(rgb(p.empty() ? C_MUTED : LEVEL_COLORS[s.level]));
    fl_draw(p.empty() ? "" : fmt(tx::STRENGTH_T, {level_name(s.level), std::to_string((int)s.bits)}).c_str(), x(), y() + 22);
  }
};
Fl_Box* dlg_label(int x, int y, int w, const char* t, bool bold = true) {
  Fl_Box* b = new Fl_Box(x, y, w, 20, t);
  b->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT);
  b->labelsize(12);
  b->labelfont(bold ? FL_HELVETICA_BOLD : FL_HELVETICA);
  b->labelcolor(rgb(C_MUTED));
  return b;
}
Fl_Input* dlg_input(int x, int y, int w, const std::string& v, int h = 32) {
  Fl_Input* in = new Fl_Input(x, y, w, h);
  in->value(v.c_str());
  in->textsize(15);
  in->box(FL_BORDER_BOX);
  return in;
}
Fl_Button* dlg_button(int x, int y, int w, int h, const char* t, bool primary) {
  Fl_Button* b = new Fl_Button(x, y, w, h, t);
  b->box(FL_RFLAT_BOX);
  b->color(rgb(primary ? C_ACCENT : 0xeef0f5));
  b->labelcolor(primary ? FL_WHITE : rgb(C_TEXT));
  b->labelfont(FL_HELVETICA_BOLD);
  b->labelsize(14);
  return b;
}
// Correr una ventana modal hasta que se cierra; «result» lo pone el botón.
int run_modal(Fl_Double_Window& win, int& result) {
  win.set_modal();
  win.show();
  while (win.shown()) Fl::wait();
  return result;
}

// ---- el generador de contraseñas
class GeneratorWin {
public:
  GenOptions opt;
  std::string value;
  Fl_Double_Window* win = nullptr;
  Fl_Output* out = nullptr;
  Fl_Value_Slider* len = nullptr;
  Fl_Check_Button *up = nullptr, *lo = nullptr, *dg = nullptr, *sy = nullptr, *amb = nullptr;
  Fl_Box* info = nullptr;
  std::string info_text;
  void regen() {
    opt.length = (int)len->value();
    opt.upper = up->value();
    opt.lower = lo->value();
    opt.digits = dg->value();
    opt.symbols = sy->value();
    opt.no_ambiguous = amb->value();
    value = generate(opt);
    out->value(value.c_str());
    double bits = generated_bits(opt);
    int lvl = bits < 36 ? 0 : bits < 60 ? 1 : bits < 80 ? 2 : bits < 110 ? 3 : 4;
    info_text = fmt(tx::STRENGTH_T, {level_name(lvl), std::to_string((int)bits)});
    info->label(info_text.c_str());
    info->labelcolor(rgb(LEVEL_COLORS[lvl]));
    win->redraw();
  }
  // Devuelve la contraseña elegida («use»: con el botón «Usar»), o vacío.
  std::string run(bool use) {
    int result = 0;
    Fl_Group::current(nullptr);
    Fl_Double_Window w(520, 330, tx::GEN_TITLE);
    win = &w;
    w.color(FL_WHITE);
    dlg_label(24, 18, 470, tx::GEN_TITLE);
    out = new Fl_Output(24, 44, 472, 48);
    out->textfont(FL_COURIER_BOLD);
    out->textsize(19);
    out->box(FL_BORDER_BOX);
    out->color(rgb(0xf5f6fa));
    info = dlg_label(24, 98, 300, "", true);
    dlg_label(24, 130, 120, tx::GEN_LENGTH);
    len = new Fl_Value_Slider(140, 130, 356, 24);
    len->type(FL_HOR_NICE_SLIDER);
    len->bounds(8, 64);
    len->step(1);
    len->value(opt.length);
    len->textsize(13);
    up = new Fl_Check_Button(24, 168, 150, 26, "A-Z");
    lo = new Fl_Check_Button(180, 168, 150, 26, "a-z");
    dg = new Fl_Check_Button(336, 168, 150, 26, "0-9");
    sy = new Fl_Check_Button(24, 198, 150, 26, "!#$%&&*");   // «&&»: FLTK lee «&» como atajo
    amb = new Fl_Check_Button(180, 198, 300, 26, tx::GEN_AMBIGUOUS);
    up->value(opt.upper);
    lo->value(opt.lower);
    dg->value(opt.digits);
    sy->value(opt.symbols);
    amb->value(opt.no_ambiguous);
    for (Fl_Widget* c : {(Fl_Widget*)len, (Fl_Widget*)up, (Fl_Widget*)lo, (Fl_Widget*)dg, (Fl_Widget*)sy, (Fl_Widget*)amb})
      c->callback([](Fl_Widget*, void* d) { static_cast<GeneratorWin*>(d)->regen(); }, this);
    Fl_Button* again = dlg_button(24, 270, 130, 38, tx::GEN_AGAIN, false);
    again->callback([](Fl_Widget*, void* d) { static_cast<GeneratorWin*>(d)->regen(); }, this);
    Fl_Button* copy = dlg_button(use ? 220 : 366, 270, 130, 38, tx::GEN_COPY, !use);
    Fl_Button* ok = use ? dlg_button(366, 270, 130, 38, tx::GEN_USE, true) : nullptr;
    struct Ctx {
      int* r;
      Fl_Window* w;
    } c1{&result, &w}, c2{&result, &w};
    copy->callback([](Fl_Widget*, void* d) {
      auto* c = static_cast<Ctx*>(d);
      *c->r = 2;
      c->w->hide();
    }, &c1);
    if (ok)
      ok->callback([](Fl_Widget*, void* d) {
        auto* c = static_cast<Ctx*>(d);
        *c->r = 1;
        c->w->hide();
      }, &c2);
    w.end();
    regen();
    if (shoot(w)) return "";
    run_modal(w, result);
    if (result == 2) return "copy:" + value;
    return result == 1 ? value : "";
  }
};

// Los menús de FLTK leen «/», «&», «_» y «\\» como órdenes: se escapan.
std::string menu_escape(const std::string& s) {
  std::string o;
  for (char c : s) {
    if (c == '/' || c == '_' || c == '\\') o += '\\';
    if (c == '&') o += '&';
    o += c;
  }
  return o;
}
// ---- una entrada: todo en una ventana
struct EntryForm {
  std::string title, user, pass, url, notes;
  int group = 0;
  std::vector<std::string> groups;   // «Personal › Bancos»
};
bool entry_dialog(EntryForm& f, bool is_new) {
  int result = 0;
  Fl_Group::current(nullptr);
  Fl_Double_Window w(560, 540, is_new ? tx::NEW_ENTRY_TITLE : tx::EDIT_ENTRY_TITLE);
  w.color(FL_WHITE);
  dlg_label(24, 14, 240, tx::F_TITLE);
  Fl_Input* title = dlg_input(24, 36, 330, f.title);
  dlg_label(370, 14, 160, tx::F_GROUP);
  Fl_Choice* group = new Fl_Choice(370, 36, 166, 32);
  for (const auto& g : f.groups) group->add(menu_escape(g).c_str());
  group->value(std::max(0, std::min(f.group, (int)f.groups.size() - 1)));
  dlg_label(24, 80, 240, tx::F_USER);
  Fl_Input* user = dlg_input(24, 102, 512, f.user);
  dlg_label(24, 146, 240, tx::F_PASSWORD);
  Fl_Input* pass = dlg_input(24, 168, 412, f.pass);
  pass->type(FL_SECRET_INPUT);
  pass->textfont(FL_COURIER);
  Fl_Button* eye = dlg_button(444, 168, 42, 32, "👁", false);
  Fl_Button* dice = dlg_button(494, 168, 42, 32, "🎲", false);
  StrengthBar* bar = new StrengthBar(24, 208, 300, 30);
  bar->source = pass;
  pass->when(FL_WHEN_CHANGED);
  pass->callback([](Fl_Widget*, void* d) { static_cast<Fl_Widget*>(d)->redraw(); }, bar);
  eye->callback([](Fl_Widget*, void* d) {
    Fl_Input* p = static_cast<Fl_Input*>(d);
    p->type(p->type() == FL_SECRET_INPUT ? FL_NORMAL_INPUT : FL_SECRET_INPUT);
    p->redraw();
  }, pass);
  struct Dice {
    Fl_Input* pass;
    StrengthBar* bar;
  } dc{pass, bar};
  dice->callback([](Fl_Widget*, void* d) {
    auto* c = static_cast<Dice*>(d);
    std::string v = generate(GenOptions());
    c->pass->value(v.c_str());
    wipe(v);
    c->bar->redraw();
  }, &dc);
  dlg_label(24, 248, 240, tx::F_URL);
  Fl_Input* url = dlg_input(24, 270, 512, f.url);
  dlg_label(24, 314, 240, tx::F_NOTES);
  Fl_Multiline_Input* notes = new Fl_Multiline_Input(24, 336, 512, 130);
  notes->value(f.notes.c_str());
  notes->textsize(14);
  notes->box(FL_BORDER_BOX);
  notes->wrap(1);
  Fl_Button* cancel = dlg_button(296, 484, 112, 38, tx::CANCEL, false);
  Fl_Button* save = dlg_button(420, 484, 116, 38, tx::SAVE_BTN, true);
  struct Ctx {
    int* r;
    Fl_Window* w;
  } ok{&result, &w}, no{&result, &w};
  save->callback([](Fl_Widget*, void* d) {
    auto* c = static_cast<Ctx*>(d);
    *c->r = 1;
    c->w->hide();
  }, &ok);
  cancel->callback([](Fl_Widget*, void* d) { static_cast<Ctx*>(d)->w->hide(); }, &no);
  w.end();
  if (shoot(w)) return false;
  run_modal(w, result);
  if (result != 1) return false;
  f.title = title->value();
  f.user = user->value();
  f.pass = pass->value();
  f.url = url->value();
  f.notes = notes->value();
  f.group = group->value();
  pass->value("");
  return true;
}

// ---- base de datos nueva, clave maestra y seguridad
struct DbForm {
  std::string name, pass, pass2;
  bool keyfile = false;   // crear también un archivo de clave
  int cipher = 0;         // 0 AES-256, 1 ChaCha20
  int kdf = 0;            // 0 Argon2d, 1 Argon2id, 2 AES-KDF
  int time = 1;           // 0 medio segundo, 1 un segundo, 2 dos segundos
  bool ask_name = true, ask_pass = true, ask_security = true;
};
bool db_dialog(DbForm& f, const char* title) {
  int result = 0;
  Fl_Group::current(nullptr);
  int H = 70 + (f.ask_name ? 66 : 0) + (f.ask_pass ? 172 : 0) + (f.ask_security ? 150 : 0) + 60;
  Fl_Double_Window w(520, H, title);
  w.color(FL_WHITE);
  int y = 16;
  Fl_Box* head = new Fl_Box(24, y, 472, 30, title);
  head->align(FL_ALIGN_INSIDE | FL_ALIGN_LEFT);
  head->labelfont(FL_HELVETICA_BOLD);
  head->labelsize(18);
  y += 46;
  Fl_Input *name = nullptr, *p1 = nullptr, *p2 = nullptr;
  Fl_Check_Button* kf = nullptr;
  Fl_Choice *ci = nullptr, *kd = nullptr, *tm = nullptr;
  if (f.ask_name) {
    dlg_label(24, y, 300, tx::DB_NAME);
    name = dlg_input(24, y + 22, 472, f.name);
    y += 66;
  }
  if (f.ask_pass) {
    dlg_label(24, y, 300, tx::DB_PASS);
    p1 = dlg_input(24, y + 22, 472, f.pass);
    p1->type(FL_SECRET_INPUT);
    StrengthBar* bar = new StrengthBar(24, y + 60, 300, 30);
    bar->source = p1;
    p1->when(FL_WHEN_CHANGED);
    p1->callback([](Fl_Widget*, void* d) { static_cast<Fl_Widget*>(d)->redraw(); }, bar);
    dlg_label(24, y + 92, 300, tx::DB_PASS2);
    p2 = dlg_input(24, y + 114, 472, f.pass2);
    p2->type(FL_SECRET_INPUT);
    kf = new Fl_Check_Button(24, y + 150, 472, 22, tx::DB_KEYFILE);
    kf->value(f.keyfile);
    kf->labelsize(13);
    y += 182;
  }
  if (f.ask_security) {
    dlg_label(24, y, 472, tx::DB_SECURITY);
    dlg_label(24, y + 24, 140, tx::DB_CIPHER, false);
    ci = new Fl_Choice(170, y + 22, 326, 28);
    ci->add("AES-256");
    ci->add("ChaCha20");
    ci->value(f.cipher);
    dlg_label(24, y + 58, 140, tx::DB_KDF, false);
    kd = new Fl_Choice(170, y + 56, 326, 28);
    kd->add(tx::KDF_ARGON2D);
    kd->add(tx::KDF_ARGON2ID);
    kd->add(tx::KDF_AES);
    kd->value(f.kdf);
    dlg_label(24, y + 92, 140, tx::DB_TIME, false);
    tm = new Fl_Choice(170, y + 90, 326, 28);
    tm->add(tx::TIME_HALF);
    tm->add(tx::TIME_ONE);
    tm->add(tx::TIME_TWO);
    tm->value(f.time);
    y += 140;
  }
  Fl_Button* cancel = dlg_button(256, H - 54, 112, 38, tx::CANCEL, false);
  Fl_Button* ok = dlg_button(380, H - 54, 116, 38, tx::ACCEPT, true);
  struct Ctx {
    int* r;
    Fl_Window* w;
  } c1{&result, &w}, c2{&result, &w};
  ok->callback([](Fl_Widget*, void* d) {
    auto* c = static_cast<Ctx*>(d);
    *c->r = 1;
    c->w->hide();
  }, &c1);
  cancel->callback([](Fl_Widget*, void* d) { static_cast<Ctx*>(d)->w->hide(); }, &c2);
  w.end();
  if (shoot(w)) return false;
  run_modal(w, result);
  if (result != 1) return false;
  if (name) f.name = name->value();
  if (p1) {
    f.pass = p1->value();
    f.pass2 = p2->value();
    f.keyfile = kf->value();
    p1->value("");
    p2->value("");
  }
  if (ci) {
    f.cipher = ci->value();
    f.kdf = kd->value();
    f.time = tm->value();
  }
  return true;
}

// Dos bases de datos de verdad para las pruebas (creadas por KeePassXC y por pykeepass).
const char* const FIXTURE_3 =
    "A9mimmf7S7UBAAMAAhAAMcHy5r9xQ1C+WAUhavxa/wMEAAEAAAAEIACEQ6jP7hQHXQR+xdgE3DK/MUzkqrWVdL0jWpj8WDHXlwUgANGYhdzCo6cQxDMsgsZF"
    "7P/WOfQh/hX0Tlzg6X+Jut78BggADwhYAAAAAAAHEACbgsYFnPYL42aSU3bW4N7UCCAAXa7bgWLIgBRBgqabB8KrWgMG8pxIIXLCBc3vhRtbPbYJIADTZJhw"
    "xXYXEkNP8ToOOBePAxwMxMT03htbB+Q+BHS3wgoEAAIAAAAABAANCg0K+reTkFM4B22r+HaLesei14pnmzH/c82R/KuVw94gBj/amSWqDItfyJMt5LhJFYs4"
    "+TaVaXU2wRmYkIrPAuMaI/xYCnRSwE2WhLH/c0uIUlC90jAI6c2MYFUXyOmmBiA3Eh5w/W5yVtnsV35QYKINbl6hkUeeUc86sTjL4tO5oRiqJBsV5Oozy0Aw"
    "3brW3vgkFiNiJYtxLK1FdmKiq6ItR0zri+mhni5w4K3OUfXF2jTYiIYUExWDM3o1B5rex8T9vgjjl3rKvYIk4upH0peFObqRz89tLOc1WvFRx1pqD2T2x2vu"
    "uObRKZNE3bhn9IcJzO5hU6tD1wXcrwS+JVT14h7WUXLZCq/H5Lkwak3fC5fTTySfiSofoy9/G+DFx9bCIgDUbbkXuk3DAsNHSjQOM0/RNeZqy8FBm29+fyfC"
    "t2SckF4XnJOD2hvKzf3kQcXTEzKT1FuqnhAfcauzANHpIi9jg9UdaQZyLTGIUfED0V8SGpOzRTTN6dn5kXoHVNdiG4AZ8LdX3tGDLeMGOjw99GCWlVx9yRsu"
    "yeySSi8HqaDCiXGtFyUP/XKV8tjAUnNHtkT1YbjSRmeJq2fcAkBtiMp4QWnM9XTn7bSfxZEuIfXrOlIH35vTjPJA/RFcRTJ0V+v5rJ3itCI0wOe99JoY2Lse"
    "wmSQcrWGqITikvdnq/Zet9ycPkDVHobg5GobrTCa/1yXK3uzqfVi9lwBhnpeKJXa4KNZLGFvH6tuqbHDXg/muItodE2N/x+HSpfsxOQf9kkJxfRb1BLBjrWe"
    "Xzc7JS5zwG2o9qqP1BX6Wgn99XH86UqXCnGRr3bbMUGTucrGFh8aXSTp7SOsn2AAmDOF6Ryg8NJbSAkOVbtJNn0Rz2AgV1va4T/Qn3KckcfdK2bi7Vbf+PsT"
    "tG0Sb7nAus+52PQ620l2PeNViYm8vblXa/+4GsXcPqa5m3zkG13fgwQGqn8NzgcwWKWTkZ076X37w5UwWy9G5DA8KMec/8hC5nlit6twjGqXgYFxMjw1pk0Z"
    "R0Auir6gE4oEVGzWcB1WZ9o4cvfk0SZ9AzLr1xKdH6BraXoEIx2xQfxHcxZxUxbSkIba2CO6TD+kxGDmMzrWJVR0FUxZp+hGHAISIm4F0NrCrNkROuhUWlN1"
    "TJwTO/7QxF90cn80RGrnzlp3n2COAokeFhlPVVU+XAgSbeL6t+lJcNw26wOIWARp0qJmx+r2jPH5AMowwdPGrtChjGXIEAvL76q0uJRWVcsOIrJk8Y2/jUOt"
    "sSl93D7ZsoVp6zYhiZgAUTAPffjwzpe5wj88tDF46QSd6zekJG1C2G9fnkCl4nKt/0D9YXtW6Ic+bqpMj1miBSoHiNnmj5ZcLAK2bGuHuMNN7rop/G7WOmHF"
    "cvicdn/xXkaig4UKgS0KVocOXmEasu4LsV004p5BmVAIL28OUKAUR5Qh6ei9XdOEFgVjfp2Fb684keeyPhGuUK89JuDABi9n8AbTNS0lP7CSosdLkZ5Sq2Hs"
    "XvjmyeDQmnSyvfCbFCEUevZ8S4IcZkuxfam7kV6gFUDOGB0pAmkg/4cYBmpqvw4447g5TTbd5gteWOx1Gk4NdjBk7lYYTsIl5rdy7s+uPYvpri9iBhG1EgDz"
    "2p3o0Z0bw782WdwCML81GkUcRmPToFnmDeXQ3IjQMCnlrHIVhRWqoQHuHdvnRVLaRERIZOtmCU1a4XxfGdPe5IYwJLCDtjlgpktCUAinCLI5/dgA4UUsEjpG"
    "nzFuUwcq6+klvcsZKU+GzwFmUzti+OLz9saj0E3acR6HpF/X/KICl+dRHtyltecISutJNMs2M6p/7LlwCLdFhlr2amPiSg2W2PRnmZbpaSKch2PXdtoFhu4a"
    "EicrasPswR79K5pU6yY+IRjX/bjAt2vlxGv3/YNIAbgGx4FEYMpphJegvmtmLsyHgi7gVL4iHxsQluLQk8Q8TwOut44ke2zcDXSEtt9CsviCIFW2Jydistnc"
    "1aIobTNhJx1Il7Zup6JfDI6+kTU2Aot2Q3sExwbqsqujzE7ZptPATgv/Kdz9zyaNzftFUysqsrdNSBT7vPht1lNxPey+Mp2zOmrhHXDOKpYQvhWvIchFzMKI"
    "CwJDDNVPLOMEaDrZXLPvkFcmRKXIBW/gZpAi3bxO5YLqiitboQownCCsaV71bNS1+Lbw+RxJK9TF8+AwCMJs9xoJH5Nl3zUKlW6gcw5GksOWeLtbfc7IOIMr"
    "NV0BkpClwzKRchH9Kvn0FfpWhYlM7xYDeyD35at3cWAK1/ZxXMOGS/7VHM8gnoqsB7MG33Av24p3/DCcBm5/4ModnfRpKtz8gvq+J+VwlXDNFR3OADMuIwtg"
    "w/bHQ0muRszu819K12J30bXPXgC7Pv0kST7oUnVtqpZJwAnmKHVqdR4zmXLodGpaJwAQR5PubJtZpAWTyiqFI20F3z5+JbkSw8toxINYucfPiFKyAQJSpw7M"
    "lFBEAOHvwmH5DpzCRx6xEanFOBAb7KbzwcFNGGsqNLugEmkkVFYByygVz7DZmhNAOWWEu4NLypIAYItKVRsp16JNOF2jNkd3mFdg5SaY87ZYGaodoElRPKiL"
    "SXTUVx5Qu7bszbP3y1j6gAIc3p0FAj/jn2ezIe4IAto+0DXf3biv7TF9pIT7TA=="
    ;
const char* const FIXTURE_4 =
    "A9mimmf7S7UAAAQAAhAAAAAxwfLmv3FDUL5YBSFq/Fr/AwQAAAABAAAABCAAAACagb7EZVsA5iQl+/xUY8HDPNwNl6tWSIE/YaQeIU/0RQcQAAAAaejhOBiX"
    "ce9HEBDDAxKEdguLAAAAAAFCBQAAACRVVUlEEAAAAO9jbd+MKURLkfeppAPjCgwFAQAAAEkIAAAAAgAAAAAAAAAFAQAAAE0IAAAAAAAQAAAAAAAEAQAAAFAE"
    "AAAAAQAAAEIBAAAAUyAAAAD6extGcnO881ZN4dnsTWf+zk1uHO+xvh04vwU+D7nPbgQBAAAAVgQAAAATAAAAAAAEAAAADQoNCqo/tgMyF92j62Z8OdI7cnWD"
    "jLK0yD+t4LfB+QjV8CxcYVlsNltDQeSc7Q+65OoqJ579w3qH6Bbeinuxi4EtdVHPkMCYaBD+QiSxmtedLWnTAcZ+/3c6N49dWq/nspknFvAEAAC8Th8GH2YC"
    "pxVH/WzQzh3359g2Q7VpJ6e8R/Z6u564gHxN3jkplqtUjliUtTd/LC08qNSCwUaOqB6Vi7Y11F/sF5BcLWT/zZiO0XyF1SdEsiHEQasxEbRPz4WD3fMlClml"
    "psGYigpJIG0oEHoeSt93ZpWVr8w0TKkN8KrBzeOJdL8Itg1ktyyxbB0qIg9Fe2Tw+Nb0+0QymqaH7MO23r4R5BRrnJuNYqsBE9tl4m1W9Uf4EobInUhIDKci"
    "cUJHoqOi/AGzwV4uUJJAZr2UZRo2m0+hj39FUCMJw8cR5ga9ijy4LpCB0AcYgxWK4QrO4LiyLATLoqSYCoVoBXNQKnc2Pp1Nf7qearLFS8N3dgHCvroyOjlU"
    "/5xpv3XPow78isfChXL26Ac6PjwwFapEW4DOF014gOAJNTuKY3jpKcHpLU7nkZ4pyZh5g1VYF9yG7O2Hr7zzpwRWW28Rxobwm3ONwMrED7EGCv/zWCmO8KD8"
    "ligsTkCj2dbDyH+pA+Jb7oZWX7BP+WJMeHUiuZD75EqjLo6SqNrT9lTCe1H+D/7Nea9o07MKV4PIs7exbkrlKobHC4TBELlIJ5iVpxlV+cK+f8w97s8+cJUw"
    "nnk3mvF/nTr3ssxJCvNDhX9PDDunWJ2y2sUPiF+WOTpT7Y41KT+X09F9fzR+bftJkUlT6YSThUx+dD99tZHh1eJyMk32HUOOV1Qy3jLGrgXlpLwKgfwOuOVz"
    "CbzVeCPQbb1laluyavDgR7Pn7slySSFho8vd3dt4jWEvplpY8ISoGXQhxDeQQt86CNiGy5HMgQbMHlw8xkxX8RtyYQOnK857UO6T0FBXORwcvvQWqCsOaH2c"
    "CAeQawbu8SV1BT4VyxFNgRYYs2RLBr5121UF86/+p9h8z+qUwA8VgmbFjfQ6pE6aiF7/V7jpNJ0g/r93t87omnpb/pi0oHpCxNoEAKVjFk2EqXjNPFrj+yff"
    "5WBIrKEJzVPVO7utZoMp9qUMJtZSgK4abNbPpO0MuuBtZHkH6uxznHhTmWUWPsp4tuPed1HWe4m6RB4CYs7f06mye0Kp02geePtQ8eGrrujjjMpiaSSrdX65"
    "TWhgQIuwjgBvP9/JW1JPmOCBgIGHOKLhv+tBfYZ9l3J3Rgovg/zOpPjIwFsJmXh9uwUKFnfMoDsJufQZUJNdH11muWJIz+h3exiPgrbqCMlt+rvYqDiG9tZm"
    "5zxc9gAW1+G67UzvOU9Ce+kg/1lr8e7XKZOg7QAgoav1OlyNcaZwr4SO7ixzxkoiB5Q94R/zzUPaFidDuKLBoUmunGHaZNGtLvPphHowaoem4WJlIPCPfoUP"
    "HS7vdvnmU8uHIxKuFYH5lPC8mt9jYZ9pMQkeL6wWu+GKnAaW4atVGpIYdhrS4iiX5gFKEI/uc+ns/Y8GYYVLSDKlpg2kX/LWl77JHezY22VSwBuL/tUlpff5"
    "ZccHlxRQwekobvtVNJwrjEmnUddu2kzjN+cJORcsTT2wagnnD0HQfsCIiXHZdrPjO//enCWg4v7EFcNcxCaZ1Tmj7mGjXK2r/f4nsT5cPn1fxppZfB4P5B9f"
    "Yz8ePZZ05yNSOneJCv/GjEfgD6poZhQKUbIm/m8DASrAxu1WXKYzo/2zPR+iadsTp7PmUS34psNdkW4Sfpsoq2q107sBKhQG7dEtxSHvaMFl5ayN4767wUC2"
    "9ecaMu+nnexs4UbtbFYE84I/gmw6zgd67DCv2AAAAAAA"
    ;

// ============================================================ las pruebas internas
// Los vectores oficiales de cada pieza criptográfica y dos bases de datos de
// verdad: una creada por KeePassXC (KDBX 3.1, AES-KDF) y otra por pykeepass
// (KDBX 4, Argon2d, con un adjunto y un campo protegido).
int selftest() {
  int fails = 0;
  auto chk = [&](bool ok, const char* what) {
    if (fl_getenv("DMS_PASS_TRACE")) std::printf("ok? %d %s\n", ok ? 1 : 0, what);
    if (!ok) {
      std::printf("FAIL %s\n", what);
      fails++;
    }
  };
  chk(hex(sha256(bytes("abc"))) == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "SHA-256 (FIPS 180-4)");
  chk(hex(sha512(bytes("abc"))) ==
          "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f",
      "SHA-512 (FIPS 180-4)");
  chk(hex(hmac_sha256(Bytes(20, 0x0b), bytes("Hi There"))) == "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
      "HMAC-SHA-256 (RFC 4231)");
  Bytes key = unhex("000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f"), pt = unhex("00112233445566778899aabbccddeeff");
  Bytes ct(16), back(16);
  {
    Aes256 a(key.data());
    a.encrypt(pt.data(), ct.data());
    a.decrypt(ct.data(), back.data());
  }
  chk(hex(ct) == "8ea2b7ca516745bfeafc49904b496089" && back == pt, "AES-256 (FIPS 197)");
  Bytes iv(16, 7), dec;
  chk(aes_cbc_decrypt(key, iv, aes_cbc_encrypt(key, iv, bytes("una frase de prueba para CBC")), dec) && dec == bytes("una frase de prueba para CBC") &&
          !aes_cbc_decrypt(key, iv, Bytes(15, 1), dec),
      "AES-256-CBC con PKCS#7");
  {
    Bytes n = unhex("000000000000004a00000000");
    Bytes msg = bytes("Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.");
    ChaCha20 c(key.data(), n.data(), 1);
    c.apply(msg.data(), msg.size());
    chk(hex(msg).compare(0, 32, "6e2e359a2568f98041ba0728dd0d6981") == 0 && hex(msg).compare(hex(msg).size() - 6, 6, "42874d") == 0,
        "ChaCha20 (RFC 7539)");
  }
  {
    Bytes sk(32, 0), sn(8, 0), sb(64, 0);
    sk[0] = 0x80;
    Salsa20 s(sk.data(), sn.data());
    s.apply(sb.data(), 64);
    chk(hex(sb).compare(0, 32, "e3be8fdd8beca2e3ea8ef9475b29a6e7") == 0, "Salsa20 (eSTREAM)");
  }
  chk(hex(blake2b(bytes("abc"), 64)) ==
          "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923",
      "BLAKE2b (RFC 7693)");
  Bytes P(32, 1), S(16, 2), K(8, 3), X(12, 4);
  chk(hex(argon2(ARGON2_D, P, S, 3, 32, 4, 32, K, X)) == "512b391b6f1162975371d30919734294f868e3be3984f3c1a13a4db9fabe4acb", "Argon2d (RFC 9106)");
  chk(hex(argon2(ARGON2_ID, P, S, 3, 32, 4, 32, K, X)) == "0d640df58d78766c08c037a34a8b53c9d01ef0452d75b65eb52520e96b01e659", "Argon2id (RFC 9106)");
  // gzip y base64.
  Bytes big = bytes(std::string(70000, 'x') + "fin");
  Bytes un;
  chk(gunzip(gzip_stored(big), un) && un == big && unb64(b64(bytes("hola!"))) == bytes("hola!") && b64(bytes("ab")) == "YWI=", "gzip y base64");
  // XML: escapes y lo que no se conoce, guardado.
  auto x = parse_xml("<?xml version=\"1.0\"?><A k=\"v&amp;w\"><B>1 &lt; 2 &#241;</B><C/><Raro x=\"1\"><D>e</D></Raro></A>");
  std::string xo;
  if (x) write_xml(*x, xo, 0);
  chk(x && x->attr("k") == "v&w" && x->get("B") == "1 < 2 ñ" && x->child("Raro") && xo.find("<Raro x=\"1\">") != std::string::npos &&
          xo.find("1 &lt; 2 ñ") != std::string::npos,
      "XML: escapes y lo desconocido");
  // Las bases de datos de KeePassXC y de pykeepass.
  Database db;
  std::string err;
  bool ok3 = open_kdbx(unb64(FIXTURE_3), composite_key("prueba123", Bytes()), db, err);
  Node* root = ok3 ? root_group(db) : nullptr;
  Node* banco = root && !entries(root).empty() ? entries(root)[0] : nullptr;
  chk(ok3 && db.major == 3 && db.kdf.type == K_AESKDF && banco && field(banco, "Title") == "Banco" && field(banco, "Password") == "Clave-Del-Banco-99" &&
          db.binaries.size() == 1 && db.binaries[0] == bytes("hola adjunto\n") && field(entries(groups(root)[0])[0], "Password") == "ñandú€",
      "abrir una base de datos de KeePassXC (KDBX 3.1, AES-KDF, Salsa20)");
  Database bad;
  chk(!open_kdbx(unb64(FIXTURE_3), composite_key("mala", Bytes()), bad, err) && err == ERR_KEY, "KDBX 3: contraseña mala");
  bool ok4 = open_kdbx(unb64(FIXTURE_4), composite_key("prueba123", Bytes()), db, err);
  root = ok4 ? root_group(db) : nullptr;
  Node* tw = root && !groups(root).empty() && !entries(groups(root)[0]).empty() ? entries(groups(root)[0])[0] : nullptr;
  chk(ok4 && db.major == 4 && db.kdf.type == K_ARGON2D && tw && field(tw, "Password") == "p@ss<w>&\"o'rd" && field(tw, "PIN") == "4321" &&
          field(tw, "Notes") == "Nota\ncon dos líneas ñ" && db.binaries.size() == 1,
      "abrir una base de datos de pykeepass (KDBX 4, Argon2d, ChaCha20 interno)");
  chk(!open_kdbx(unb64(FIXTURE_4), composite_key("mala", Bytes()), bad, err) && err == ERR_KEY, "KDBX 4: contraseña mala (HMAC del encabezado)");
  Bytes tampered = unb64(FIXTURE_4);
  tampered[tampered.size() - 40] ^= 1;
  chk(!open_kdbx(tampered, composite_key("prueba123", Bytes()), bad, err) && err == ERR_CORRUPT, "KDBX 4: un byte cambiado se detecta");
  // Guardar y volver a abrir, con cada cifrado y cada derivación.
  int combos = 0;
  for (int c = 0; c < 2; c++)
    for (int k = 0; k < 3; k++) {
      Database d;
      new_database(d, "Prueba");
      d.cipher = c ? C_CHACHA : C_AES;
      d.kdf.type = (KdfType)k;
      d.kdf.iterations = k == K_AESKDF ? 1000 : 2;
      d.kdf.memory = 1 << 20;
      Node* e = new_entry(d, root_group(d));
      set_field(d, e, "Title", "Correo <&>");
      set_field(d, e, "Password", "pässwörd-🙂");
      Bytes out, kk = composite_key("clave", Bytes());
      Database r;
      if (save_kdbx(d, kk, out, err) && open_kdbx(out, kk, r, err) && field(entries(root_group(r))[0], "Password") == "pässwörd-🙂" &&
          field(entries(root_group(r))[0], "Title") == "Correo <&>" && r.cipher == d.cipher && r.kdf.type == d.kdf.type)
        combos++;
    }
  chk(combos == 6, "guardar y abrir: AES-256 y ChaCha20 con Argon2d, Argon2id y AES-KDF");
  // KDBX 3 → 4: los adjuntos pasan al encabezado interno y las fechas, a segundos.
  open_kdbx(unb64(FIXTURE_3), composite_key("prueba123", Bytes()), db, err);
  db.kdf.type = K_ARGON2D;
  db.kdf.iterations = 2;
  db.kdf.memory = 1 << 20;
  Bytes out;
  Database r4;
  chk(save_kdbx(db, composite_key("prueba123", Bytes()), out, err) && open_kdbx(out, composite_key("prueba123", Bytes()), r4, err) &&
          r4.major == 4 && r4.binaries.size() == 1 && r4.binaries[0] == bytes("hola adjunto\n") &&
          parse_time(entries(root_group(r4))[0]->child("Times")->get("CreationTime")) > 1700000000,
      "KDBX 3 se guarda como KDBX 4 (adjuntos y fechas)");
  // Archivos de clave: el XML 2.0 que crea DMarlonPass, 32 bytes y 64 hexadecimales.
  std::string kf = make_keyfile();
  Bytes kfk = keyfile_key(bytes(kf));
  chk(kfk.size() == 32 && keyfile_key(Bytes(32, 5)) == Bytes(32, 5) && keyfile_key(bytes(std::string(64, 'a'))) == Bytes(32, 0xaa) &&
          keyfile_key(bytes("cualquier cosa")) == sha256(bytes("cualquier cosa")),
      "archivos de clave");
  // Fuerza, generador y revisión.
  chk(strength("123456").level == 0 && strength("Tr0ub4dor&3").level >= 1 && strength("correct horse battery staple").level >= 3 &&
          strength("aaaaaaaaaaaaaaaa").bits < strength("q8#Lz!2vR@pW").bits,
      "la fuerza de una contraseña");
  GenOptions go;
  go.length = 24;
  std::string g = generate(go);
  bool has[4] = {false, false, false, false};
  for (char c : g) {
    has[0] |= std::isupper((unsigned char)c) != 0;
    has[1] |= std::islower((unsigned char)c) != 0;
    has[2] |= std::isdigit((unsigned char)c) != 0;
    has[3] |= !std::isalnum((unsigned char)c);
  }
  bool no_amb = g.find_first_of("Il1O0o") == std::string::npos;
  chk(g.size() == 24 && has[0] && has[1] && has[2] && has[3] && no_amb && generate(go) != g, "el generador: largo, de todo y sin ambiguos");
  Database ad;
  new_database(ad, "Revisión");
  for (const char* p : {"1234", "1234", "Bien-Larga-Y-Unica-2026!", ""}) {
    Node* e = new_entry(ad, root_group(ad));
    set_field(ad, e, "Title", p);
    set_field(ad, e, "Password", p);
  }
  auto fs = audit(ad, unix_now());
  chk(fs.size() == 3 && (fs[0].issues & I_EMPTY) && (fs[1].issues & I_REUSED) && fs[1].reused == 2 && (fs[1].issues & I_WEAK),
      "la revisión: vacías, débiles y repetidas");
  // El historial y la papelera.
  Node* e = entries(root_group(ad))[2];
  backup(ad, e);
  set_field(ad, e, "Password", "otra");
  remove_node(ad, e);
  Node* bin = recycle_bin(ad, false);
  chk(e->child("History")->kids.size() == 1 && bin && e->parent == bin && is_recycle_bin(ad, bin), "el historial y la papelera");
  remove_node(ad, e);
  chk(entries(bin).empty() && ad.xml->child("Root")->child("DeletedObjects")->kids.size() == 1, "borrar desde la papelera: para siempre");
  if (!fails) std::printf("selftest ok\n");
  return fails ? 1 : 0;
}

}  // namespace kp

// ============================================================ la ventana
class Form1 : public FormDesign {
public:
  kp::VaultView* view = nullptr;
  kp::Database db;
  kp::Bytes master_key;              // la clave compuesta, mientras está abierta
  bool unlocked = false, dirty = false, demo = false;
  std::string path, keyfile_path, message;
  double message_until = 0, last_touch = 0, clip_until = 0;
  int lock_minutes = 5, clip_seconds = 20;
  std::vector<kp::Node*> group_nodes;
  kp::Node* cur_group = nullptr;
  std::string search;
  std::string title_text;
  // Para las pruebas: elegir archivos, preguntar, copiar y abrir enlaces sin ventanas.
  std::function<std::string()> pick_open, pick_save, pick_key;
  std::function<bool(const std::string&)> confirm = [](const std::string& q) {
    return fl_choice("%s", tx::NO, tx::YES, nullptr, q.c_str()) == 1;
  };
  std::function<int(const std::string&)> ask_save = [](const std::string& q) {
    return fl_choice("%s", tx::CANCEL, tx::DONT_SAVE, tx::SAVE_BTN, q.c_str());   // 0 cancelar, 1 no guardar, 2 guardar
  };
  std::function<std::string(const std::string&, const std::string&)> ask_text = [](const std::string& q, const std::string& v) {
    const char* r = fl_input("%s", v.c_str(), q.c_str());
    return std::string(r ? r : "\x01");
  };
  std::function<int(const std::vector<std::string>&)> choose = [](const std::vector<std::string>& items) {
    std::vector<Fl_Menu_Item> m;
    for (const auto& i : items) m.push_back({i.c_str(), 0, nullptr, nullptr, 0, 0, 0, 0, 0});
    m.push_back({nullptr, 0, nullptr, nullptr, 0, 0, 0, 0, 0});
    const Fl_Menu_Item* r = m[0].popup(Fl::event_x(), Fl::event_y());
    return r ? (int)(r - &m[0]) : -1;
  };
  std::function<bool(kp::EntryForm&, bool)> entry_form = kp::entry_dialog;
  std::function<bool(kp::DbForm&, const char*)> db_form = kp::db_dialog;
  std::function<std::string(bool)> gen_dialog = [](bool use) {
    kp::GeneratorWin g;
    return g.run(use);
  };
  std::function<void(const std::string&)> copy = [](const std::string& s) { Fl::copy(s.c_str(), (int)s.size(), 1); };
  std::function<void(const std::string&)> open_url = [](const std::string& u) { fl_open_uri(u.c_str()); };

  static Form1*& self() {
    static Form1* f = nullptr;
    return f;
  }
  Form1() {
    if (fl_getenv("DMS_PASS_SELFTEST")) std::exit(kp::selftest());
    if (fl_getenv("DMS_PASS_UITEST")) { set_fonts(); std::exit(ui_test()); }
    if (const char* d = fl_getenv("DMS_PASS_SHOT")) { set_fonts(); std::exit(shots(d)); }
  }
  static void set_fonts() {
#ifdef _WIN32
    Fl::set_font(FL_HELVETICA, " Segoe UI");
    Fl::set_font(FL_HELVETICA_BOLD, "BSegoe UI");
#elif defined(__APPLE__)
    Fl::set_font(FL_HELVETICA, "HelveticaNeue");
    Fl::set_font(FL_HELVETICA_BOLD, "HelveticaNeue-Bold");
#endif
  }
  void setup() {
    self() = this;
    BoardHint->hide();
    Board->box(FL_FLAT_BOX);
    Top->box(FL_FLAT_BOX);
    Top->resizable(Search);
    resizable(Board);
    view = new kp::VaultView(Board->x(), Board->y(), Board->w(), Board->h());
    Board->add(view);
    Board->resizable(view);
    Board->add(Master);
    Board->add(BtnUnlock);
    Master->textsize(16);
    Master->box(FL_BORDER_BOX);
    BtnUnlock->box(FL_RFLAT_BOX);
    for (Fl_Button* b : {(Fl_Button*)BtnAdd, (Fl_Button*)BtnGen, (Fl_Button*)BtnLock, (Fl_Button*)BtnSave}) b->box(FL_RFLAT_BOX);
    for (Fl_Button* b : {(Fl_Button*)BtnGen, (Fl_Button*)BtnLock}) b->color(kp::rgb(0xeef0f5));
    Search->label("🔍");
    Search->align(FL_ALIGN_LEFT);
    Search->box(FL_BORDER_BOX);
    Search->when(FL_WHEN_CHANGED | FL_WHEN_ENTER_KEY_ALWAYS);
    Search->callback([](Fl_Widget*, void*) { if (self()) self()->search_changed(); });
    view->on_act = [](int a, int i) { if (self()) self()->act(a, i); };
    view->on_context = [](int a, int i) { if (self()) self()->context(a, i); };
    view->on_key = [](int k) { return self() && self()->key(k); };
    pick_open = [this] { return DlgOpen.execute(); };
    pick_save = [this] { return DlgSave.execute(); };
    pick_key = [this] { return DlgKey.execute(); };
    callback([](Fl_Widget*, void*) {
      if (Fl::event() == FL_SHORTCUT && Fl::event_key() == FL_Escape) return;
      if (self() && self()->can_close()) self()->close_now();
    });
    Fl::event_dispatch(dispatch);
  }
  void form_create() override {
    set_fonts();
    setup();
    load_settings();
    view->mode = path.empty() ? kp::M_WELCOME : kp::M_LOCKED;
    last_touch = kp::now_s();
    refresh();
    if (view->mode == kp::M_LOCKED) Master->take_focus();
  }
  void form_close() override { close_now(); }

  // ---- los ajustes (solo rutas y tiempos: nada secreto)
  std::string settings_file() const { return kp::config_dir() + "/dmarlonpass.txt"; }
  void load_settings() {
    std::string text;
    if (demo || !kp::read_file(settings_file(), text)) return;
    for (const auto& l : kp::split(text, '\n')) {
      if (l.rfind("recent=", 0) == 0) path = l.substr(7);
      else if (l.rfind("keyfile=", 0) == 0) keyfile_path = l.substr(8);
      else if (l.rfind("lock=", 0) == 0) lock_minutes = std::max(1, std::atoi(l.c_str() + 5));
      else if (l.rfind("clip=", 0) == 0) clip_seconds = std::max(5, std::atoi(l.c_str() + 5));
    }
    if (!path.empty() && !kp::file_exists(path)) path.clear();
  }
  void save_settings() {
    if (demo) return;
    fl_make_path(kp::config_dir().c_str());
    kp::write_file(settings_file(), "recent=" + path + "\nkeyfile=" + keyfile_path + "\nlock=" + std::to_string(lock_minutes) +
                                        "\nclip=" + std::to_string(clip_seconds) + "\n");
  }

  // ---- lo que se ve
  void say(const std::string& m) {
    message = m;
    message_until = kp::now_s() + 5;
    refresh();
  }
  std::string file_name() const {
    size_t k = path.find_last_of("/\\");
    return k == std::string::npos ? path : path.substr(k + 1);
  }
  void flatten(kp::Node* g, int depth) {
    int n = (int)kp::entries(g).size();
    view->rows.push_back({g, depth, n, kp::is_recycle_bin(db, g)});
    group_nodes.push_back(g);
    for (kp::Node* k : kp::groups(g)) flatten(k, depth + 1);
  }
  void matches(kp::Node* g, const std::string& q, std::vector<kp::Node*>& out) {
    if (kp::is_recycle_bin(db, g)) return;
    for (kp::Node* e : kp::entries(g)) {
      std::string all;
      for (const char* k : {"Title", "UserName", "URL", "Notes"}) all += kp::lower(kp::field(e, k)) + "\n";
      if (all.find(q) != std::string::npos) out.push_back(e);
    }
    for (kp::Node* k : kp::groups(g)) matches(k, q, out);
  }
  void refresh() {
    bool vault = unlocked && view->mode == kp::M_VAULT;
    kp::Node* sel = view->selected >= 0 && view->selected < (int)view->list.size() ? view->list[(size_t)view->selected] : nullptr;
    view->rows.clear();
    group_nodes.clear();
    view->list.clear();
    view->findings.clear();
    view->now = kp::unix_now();
    if (vault) {
      flatten(kp::root_group(db), 0);
      if (!cur_group || std::find(group_nodes.begin(), group_nodes.end(), cur_group) == group_nodes.end()) cur_group = group_nodes[0];
      view->group = (int)(std::find(group_nodes.begin(), group_nodes.end(), cur_group) - group_nodes.begin());
      auto fs = kp::audit(db, kp::unix_now());
      view->audit_count = (int)fs.size();
      view->searching = !search.empty();
      if (view->auditing) {
        view->findings = fs;
        for (const auto& f : fs) view->list.push_back(f.entry);
      } else if (view->searching) matches(kp::root_group(db), kp::lower(search), view->list);
      else view->list = kp::entries(cur_group);
      std::string p;
      for (kp::Node* g = cur_group; g && g->name == "Group"; g = g->parent) p = g->get("Name") + (p.empty() ? "" : " › " + p);
      view->group_path = p;
      // La elegida sigue elegida si sigue en la lista.
      view->selected = -1;
      for (int i = 0; i < (int)view->list.size(); i++)
        if (view->list[(size_t)i] == sel) view->selected = i;
    }
    view->file_name = file_name();
    std::string kf = keyfile_path;
    size_t k = kf.find_last_of("/\\");
    view->key_file_name = k == std::string::npos ? kf : kf.substr(k + 1);
    layout();
    // La barra de estado y el título.
    if (!message.empty() && kp::now_s() < message_until) Status->text(" " + message);
    else if (vault) {
      int total = 0;
      for (const auto& r : view->rows)
        if (!r.bin) total += r.count;
      Status->text(" 🔓 " + file_name() + (dirty ? " *" : "") + " · " + kp::fmt(tx::STATUS_ENTRIES, {std::to_string(total)}) + " · " +
                   kp::fmt(tx::STATUS_SECURITY, {db.cipher == kp::C_AES ? "AES-256" : "ChaCha20",
                                                 db.kdf.type == kp::K_AESKDF ? "AES-KDF" : db.kdf.type == kp::K_ARGON2ID ? "Argon2id" : "Argon2d"}));
    } else Status->text(view->mode == kp::M_LOCKED ? " 🔒 " + file_name() : std::string(" ") + tx::STATUS_WELCOME);
    title_text = std::string(tx::APP) + (path.empty() ? "" : " — " + file_name()) + (dirty ? " *" : "");
    copy_label(title_text.c_str());
    BtnSave->copy_label(dirty ? tx::SAVE_DIRTY : tx::SAVE);
    BtnSave->color(kp::rgb(dirty ? kp::C_ACCENT : 0xeef0f5));
    BtnSave->labelcolor(dirty ? FL_WHITE : kp::rgb(kp::C_TEXT));
    view->repaint();
  }
  // Arriba la barra (solo con la bóveda abierta); en el bloqueo, la contraseña maestra.
  void layout() {
    bool vault = view->mode == kp::M_VAULT;
    int top_h = vault ? Top->h() : 0;
    if (vault) Top->show();
    else Top->hide();
    int by = y() == 0 ? 0 : 0;
    (void)by;
    int menu_h = Top->y();
    Board->resize(0, menu_h + top_h, w(), Status->y() - menu_h - top_h);
    view->resize(Board->x(), Board->y(), Board->w(), Board->h());
    if (view->mode == kp::M_LOCKED) {
      // Se dibuja una vez para saber dónde va (draw_gate pone master_y).
      int cw = 440, ch = 400;
      int cx = view->x() + (view->w() - cw) / 2, cy = view->y() + std::max(20, (view->h() - ch) / 2);
      Master->resize(cx + 40, cy + 186, cw - 80, 38);
      BtnUnlock->resize(cx + 40, cy + 268, cw - 80, 42);
      Master->show();
      BtnUnlock->show();
    } else {
      Master->hide();
      BtnUnlock->hide();
    }
  }

  // ---- abrir, crear, guardar, bloquear
  std::string error_text(const std::string& e) const {
    if (e == kp::ERR_KEY) return tx::ERR_KEY;
    if (e == kp::ERR_FORMAT) return tx::ERR_FORMAT;
    if (e == kp::ERR_CIPHER) return tx::ERR_CIPHER;
    if (e == kp::ERR_VERSION) return tx::ERR_VERSION;
    return tx::ERR_CORRUPT;
  }
  bool read_bytes(const std::string& p, kp::Bytes& out) {
    std::string s;
    if (!kp::read_file(p, s)) return false;
    out.assign(s.begin(), s.end());
    kp::wipe(s);
    return true;
  }
  void unlock() {
    std::string pass = Master->value() ? Master->value() : "";
    kp::Bytes file, kfk;
    if (!read_bytes(path, file)) {
      view->error = tx::ERR_READ;
      refresh();
      return;
    }
    if (!keyfile_path.empty()) {
      kp::Bytes kf;
      if (!read_bytes(keyfile_path, kf)) {
        view->error = tx::ERR_KEYFILE;
        refresh();
        return;
      }
      kfk = kp::keyfile_key(kf);
      kp::wipe(kf);
    }
    view->error.clear();
    view->busy = true;
    view->repaint();
    if (!demo) Fl::flush();
    kp::Bytes k = kp::composite_key(pass, kfk);
    kp::wipe(pass);
    kp::wipe(kfk);
    std::string err;
    kp::Database d;
    bool ok = kp::open_kdbx(file, k, d, err);
    view->busy = false;
    Master->value("");
    if (!ok) {
      kp::wipe(k);
      view->error = error_text(err);
      refresh();
      if (shown()) Master->take_focus();
      return;
    }
    db = std::move(d);
    master_key = k;
    kp::wipe(k);
    unlocked = true;
    dirty = false;
    cur_group = nullptr;
    view->auditing = false;
    view->selected = -1;
    search.clear();
    Search->value("");
    view->mode = kp::M_VAULT;
    last_touch = kp::now_s();
    save_settings();
    say(db.from_v3 ? tx::OPENED_V3 : tx::OPENED);
    if (shown()) Fl::focus(view);
  }
  void open_other() {
    if (!ask_unsaved()) return;
    std::string p = pick_open();
    if (p.empty()) return;
    lock_now(false);
    path = p;
    keyfile_path.clear();
    view->mode = kp::M_LOCKED;
    view->error.clear();
    save_settings();
    refresh();
    if (shown()) Master->take_focus();
  }
  // Tiempo de apertura → parámetros de la derivación (medidos en este equipo).
  void apply_security(int cipher, int kdf, int time) {
    db.cipher = cipher == 1 ? kp::C_CHACHA : kp::C_AES;
    db.kdf.type = kdf == 1 ? kp::K_ARGON2ID : kdf == 2 ? kp::K_AESKDF : kp::K_ARGON2D;
    double ms = time == 0 ? 500 : time == 2 ? 2000 : 1000;
    if (demo) {
      // En las pruebas, rápido.
      db.kdf.memory = 1 << 20;
      db.kdf.parallelism = 1;
      db.kdf.iterations = db.kdf.type == kp::K_AESKDF ? 2000 : 2;
      return;
    }
    if (db.kdf.type == kp::K_AESKDF) db.kdf.iterations = kp::calibrate_aeskdf(ms);
    else {
      db.kdf.memory = 64ull << 20;
      db.kdf.parallelism = 2;
      db.kdf.iterations = kp::calibrate_argon2(db.kdf.type, db.kdf.memory, db.kdf.parallelism, ms);
    }
  }
  bool check_pass(const kp::DbForm& f) {
    if (f.pass.empty() && !f.keyfile) {
      say(tx::ERR_NO_PASS);
      return false;
    }
    if (f.pass != f.pass2) {
      say(tx::ERR_PASS_MATCH);
      return false;
    }
    return true;
  }
  // Un archivo de clave nuevo, al lado de la base de datos.
  bool make_keyfile(kp::Bytes& kfk) {
    std::string kpath = path.substr(0, path.find_last_of('.')) + ".keyx";
    std::string text = kp::make_keyfile();
    if (!kp::write_file(kpath, text)) {
      say(tx::ERR_WRITE);
      return false;
    }
    kfk = kp::keyfile_key(kp::bytes(text));
    kp::wipe(text);
    keyfile_path = kpath;
    return true;
  }
  void create_db() {
    if (!ask_unsaved()) return;
    kp::DbForm f;
    f.name = tx::DEFAULT_DB_NAME;
    while (true) {
      if (!db_form(f, tx::NEW_DB_TITLE)) return;
      if (check_pass(f)) break;
    }
    std::string p = pick_save();
    if (p.empty()) return;
    if (p.size() < 5 || p.compare(p.size() - 5, 5, ".kdbx") != 0) p += ".kdbx";
    lock_now(false);
    path = p;
    keyfile_path.clear();
    kp::new_database(db, f.name.empty() ? tx::DEFAULT_DB_NAME : f.name);
    // Los grupos de partida, como KeePass.
    kp::Node* root = kp::root_group(db);
    for (const char* g : {tx::G_GENERAL, tx::G_EMAIL, tx::G_BANKING, tx::G_WORK}) kp::new_group(root, g);
    apply_security(f.cipher, f.kdf, f.time);
    kp::Bytes kfk;
    if (f.keyfile && !make_keyfile(kfk)) return;
    master_key = kp::composite_key(f.pass, kfk);
    kp::wipe(f.pass);
    kp::wipe(f.pass2);
    kp::wipe(kfk);
    unlocked = true;
    cur_group = nullptr;
    view->mode = kp::M_VAULT;
    view->auditing = false;
    dirty = true;
    if (save()) say(f.keyfile ? kp::fmt(tx::CREATED_KEYFILE, {keyfile_path}) : std::string(tx::CREATED));
  }
  bool save() {
    if (!unlocked) return false;
    if (path.empty()) return save_as();
    kp::Bytes out;
    std::string err;
    if (!kp::save_kdbx(db, master_key, out, err)) {
      say(error_text(err));
      return false;
    }
    // Primero a un archivo aparte y luego se cambia el nombre: un corte no deja la base de datos a medias.
    std::string data(out.begin(), out.end());
    kp::wipe(out);
    if (!kp::write_file(path, data)) {
      say(tx::ERR_WRITE);
      return false;
    }
    dirty = false;
    save_settings();
    say(tx::SAVED);
    return true;
  }
  bool save_as() {
    std::string p = pick_save();
    if (p.empty()) return false;
    if (p.size() < 5 || p.compare(p.size() - 5, 5, ".kdbx") != 0) p += ".kdbx";
    path = p;
    return save();
  }
  // Con cambios sin guardar: ¿guardar, no guardar o cancelar?
  bool ask_unsaved() {
    if (!unlocked || !dirty) return true;
    int r = ask_save(tx::ASK_SAVE);
    if (r == 0) return false;
    if (r == 2) return save();
    return true;
  }
  // Bloquear: se borra de la memoria todo lo descifrado y la clave.
  void lock_now(bool keep_file) {
    if (unlocked && db.xml) db.xml->wipe_all();
    db = kp::Database();
    kp::wipe(master_key);
    unlocked = false;
    dirty = false;
    cur_group = nullptr;
    view->list.clear();
    view->rows.clear();
    view->selected = -1;
    view->show_password = false;
    view->auditing = false;
    search.clear();
    Search->value("");
    if (clip_until > 0) {
      copy("");
      clip_until = 0;
    }
    view->mode = keep_file && !path.empty() ? kp::M_LOCKED : kp::M_WELCOME;
    refresh();
  }
  void lock() {
    if (!unlocked) return;
    if (!ask_unsaved()) return;
    lock_now(true);
    if (shown()) Master->take_focus();
  }
  bool can_close() { return ask_unsaved(); }
  void close_now() {
    if (clip_until > 0) copy("");
    if (unlocked && db.xml) db.xml->wipe_all();
    kp::wipe(master_key);
    hide();
  }

  // ---- entradas y grupos
  kp::Node* selected_entry() const {
    return view->selected >= 0 && view->selected < (int)view->list.size() ? view->list[(size_t)view->selected] : nullptr;
  }
  void group_choices(kp::EntryForm& f, kp::Node* current) {
    f.groups.clear();
    for (size_t i = 0; i < view->rows.size(); i++) {
      std::string p;
      for (kp::Node* g = view->rows[i].g; g && g->name == "Group"; g = g->parent) p = g->get("Name") + (p.empty() ? "" : " › " + p);
      f.groups.push_back(p);
      if (view->rows[i].g == current) f.group = (int)i;
    }
  }
  void move_entry(kp::Node* e, kp::Node* to) {
    if (!to || e->parent == to) return;
    auto n = e->parent->detach(e);
    long at = -1;
    for (size_t i = 0; i < to->kids.size(); i++)
      if (to->kids[i]->name == "Group") {
        at = (long)i;
        break;
      }
    kp::Node* moved = to->adopt(std::move(n), at);
    moved->ensure("Times")->set("LocationChanged", kp::kdbx_time(kp::unix_now()));
  }
  void add_entry() {
    if (!unlocked) return;
    kp::Node* g = view->auditing || view->searching ? kp::root_group(db) : cur_group;
    if (kp::is_recycle_bin(db, g)) g = kp::root_group(db);
    kp::EntryForm f;
    f.pass = kp::generate(kp::GenOptions());   // una contraseña fuerte de partida
    group_choices(f, g);
    if (!entry_form(f, true)) {
      kp::wipe(f.pass);
      return;
    }
    kp::Node* to = f.group >= 0 && f.group < (int)view->rows.size() ? view->rows[(size_t)f.group].g : g;
    kp::Node* e = kp::new_entry(db, to);
    kp::set_field(db, e, "Title", f.title);
    kp::set_field(db, e, "UserName", f.user);
    kp::set_field(db, e, "Password", f.pass);
    kp::set_field(db, e, "URL", f.url);
    kp::set_field(db, e, "Notes", f.notes);
    kp::wipe(f.pass);
    dirty = true;
    cur_group = to;
    view->auditing = false;
    search.clear();
    Search->value("");
    refresh();
    for (int i = 0; i < (int)view->list.size(); i++)
      if (view->list[(size_t)i] == e) view->selected = i;
    say(tx::ADDED);
  }
  void edit_entry() {
    kp::Node* e = selected_entry();
    if (!e) return;
    kp::EntryForm f;
    f.title = kp::field(e, "Title");
    f.user = kp::field(e, "UserName");
    f.pass = kp::field(e, "Password");
    f.url = kp::field(e, "URL");
    f.notes = kp::field(e, "Notes");
    refresh();
    group_choices(f, e->parent);
    kp::EntryForm before = f;
    if (!entry_form(f, false)) {
      kp::wipe(f.pass);
      kp::wipe(before.pass);
      return;
    }
    bool changed = f.title != before.title || f.user != before.user || f.pass != before.pass || f.url != before.url || f.notes != before.notes;
    if (changed) {
      kp::backup(db, e);   // la versión de antes, al historial
      kp::set_field(db, e, "Title", f.title);
      kp::set_field(db, e, "UserName", f.user);
      kp::set_field(db, e, "Password", f.pass);
      kp::set_field(db, e, "URL", f.url);
      kp::set_field(db, e, "Notes", f.notes);
      kp::touch(e);
      dirty = true;
    }
    if (f.group != before.group && f.group >= 0 && f.group < (int)view->rows.size()) {
      move_entry(e, view->rows[(size_t)f.group].g);
      dirty = true;
    }
    kp::wipe(f.pass);
    kp::wipe(before.pass);
    refresh();
    for (int i = 0; i < (int)view->list.size(); i++)
      if (view->list[(size_t)i] == e) view->selected = i;
    view->repaint();
  }
  void delete_entry() {
    kp::Node* e = selected_entry();
    if (!e) return;
    kp::Node* bin = kp::recycle_bin(db, false);
    bool forever = bin && kp::inside(e, bin);
    if (!confirm(kp::fmt(forever ? tx::DELETE_FOREVER_Q : tx::DELETE_Q, {kp::field(e, "Title")}))) return;
    kp::remove_node(db, e);
    view->selected = -1;
    dirty = true;
    say(forever ? tx::DELETED_FOREVER : tx::DELETED);
  }
  void new_group() {
    if (!unlocked) return;
    std::string name = ask_text(tx::NEW_GROUP_Q, "");
    if (name == "\x01" || kp::trim(name).empty()) return;
    kp::Node* parent = cur_group && !kp::is_recycle_bin(db, cur_group) ? cur_group : kp::root_group(db);
    cur_group = kp::new_group(parent, kp::trim(name));
    view->auditing = false;
    dirty = true;
    refresh();
  }
  void group_menu(int i) {
    if (i < 0 || i >= (int)group_nodes.size()) return;
    kp::Node* g = group_nodes[(size_t)i];
    cur_group = g;
    view->auditing = false;
    refresh();
    bool root = g == kp::root_group(db);
    std::vector<std::string> items = {tx::NEW_SUBGROUP, tx::RENAME_GROUP};
    if (!root) items.push_back(tx::DELETE_GROUP);
    int r = choose(items);
    if (r == 0) new_group();
    else if (r == 1) {
      std::string name = ask_text(tx::RENAME_Q, g->get("Name"));
      if (name != "\x01" && !kp::trim(name).empty()) {
        g->set("Name", kp::trim(name));
        kp::touch(g);
        dirty = true;
        refresh();
      }
    } else if (r == 2 && !root) {
      if (!confirm(kp::fmt(tx::DELETE_GROUP_Q, {g->get("Name")}))) return;
      kp::Node* parent = g->parent;
      kp::remove_node(db, g);
      cur_group = parent;
      dirty = true;
      refresh();
    }
  }
  void entry_menu(int i) {
    if (i < 0 || i >= (int)view->list.size()) return;
    view->selected = i;
    refresh();
    std::vector<std::string> items = {tx::COPY_USER, tx::COPY_PASS, tx::OPEN_URL, tx::EDIT_BTN, tx::MOVE_TO, tx::DELETE_BTN};
    int r = choose(items);
    if (r == 0) copy_field("UserName");
    else if (r == 1) copy_field("Password");
    else if (r == 2) open_entry_url();
    else if (r == 3) edit_entry();
    else if (r == 4) {
      std::vector<std::string> names;
      for (const auto& row : view->rows) names.push_back(std::string((size_t)row.depth * 2, ' ') + row.g->get("Name"));
      int to = choose(names);
      if (to >= 0) {
        move_entry(view->list[(size_t)i], view->rows[(size_t)to].g);
        dirty = true;
        view->selected = -1;
        refresh();
      }
    } else if (r == 5) delete_entry();
  }
  // Copiar: el portapapeles se vacía solo a los pocos segundos.
  void copy_field(const char* k) {
    kp::Node* e = selected_entry();
    if (!e) return;
    std::string v = kp::field(e, k);
    if (v.empty()) return;
    copy(v);
    kp::wipe(v);
    clip_until = kp::now_s() + clip_seconds;
    say(kp::fmt(std::string(k) == "Password" ? tx::COPIED_PASS : tx::COPIED, {std::to_string(clip_seconds)}));
  }
  void open_entry_url() {
    kp::Node* e = selected_entry();
    if (!e) return;
    std::string u = kp::field(e, "URL");
    if (u.empty()) return;
    if (u.find("://") == std::string::npos) u = "https://" + u;
    open_url(u);
  }
  void generator(bool use) {
    std::string r = gen_dialog(use);
    if (r.rfind("copy:", 0) == 0) {
      copy(r.substr(5));
      clip_until = kp::now_s() + clip_seconds;
      say(kp::fmt(tx::COPIED_PASS, {std::to_string(clip_seconds)}));
    }
    kp::wipe(r);
  }
  void change_master() {
    if (!unlocked) return;
    kp::DbForm f;
    f.ask_name = f.ask_security = false;
    while (true) {
      if (!db_form(f, tx::MASTER_TITLE)) return;
      if (check_pass(f)) break;
    }
    kp::Bytes kfk;
    if (f.keyfile && !make_keyfile(kfk)) return;
    if (!f.keyfile) keyfile_path.clear();
    kp::wipe(master_key);
    master_key = kp::composite_key(f.pass, kfk);
    kp::wipe(f.pass);
    kp::wipe(f.pass2);
    kp::wipe(kfk);
    if (kp::Node* m = kp::meta(db)) m->set("MasterKeyChanged", kp::kdbx_time(kp::unix_now()));
    dirty = true;
    if (save()) say(tx::MASTER_CHANGED);
  }
  void security() {
    if (!unlocked) return;
    kp::DbForm f;
    f.ask_name = f.ask_pass = false;
    f.cipher = db.cipher == kp::C_CHACHA ? 1 : 0;
    f.kdf = db.kdf.type == kp::K_ARGON2ID ? 1 : db.kdf.type == kp::K_AESKDF ? 2 : 0;
    if (!db_form(f, tx::SECURITY_TITLE)) return;
    apply_security(f.cipher, f.kdf, f.time);
    dirty = true;
    refresh();
  }

  // ---- clics, teclas y búsqueda
  void act(int a, int i) {
    last_touch = kp::now_s();
    switch (a) {
      case 1: create_db(); break;
      case 2: open_other(); break;
      case 3: {
        std::string k = pick_key();
        if (!k.empty()) {
          keyfile_path = k;
          save_settings();
          refresh();
        }
        break;
      }
      case 4:
        keyfile_path.clear();
        save_settings();
        refresh();
        break;
      case 5: open_other(); break;
      case 10:
        if (i >= 0 && i < (int)group_nodes.size()) {
          cur_group = group_nodes[(size_t)i];
          view->auditing = false;
          view->selected = -1;
          view->list_scroll = 0;
          search.clear();
          Search->value("");
          refresh();
        }
        break;
      case 11:
        view->auditing = true;
        view->selected = -1;
        view->list_scroll = 0;
        search.clear();
        Search->value("");
        refresh();
        break;
      case 20:
        view->selected = i;
        view->show_password = false;
        view->repaint();
        break;
      case 30: copy_field("UserName"); break;
      case 31: copy_field("Password"); break;
      case 32:
        view->show_password = !view->show_password;
        view->repaint();
        break;
      case 33: open_entry_url(); break;
      case 34: copy_field("URL"); break;
      case 35: edit_entry(); break;
      case 36: delete_entry(); break;
      case 40: add_entry(); break;
    }
  }
  void context(int a, int i) {
    if (a == 10) group_menu(i);
    else if (a == 20) entry_menu(i);
  }
  bool key(int k) {
    if (view->mode != kp::M_VAULT) return false;
    int n = (int)view->list.size();
    if (k == FL_Down && n) {
      view->selected = std::min(n - 1, view->selected + 1);
      view->show_password = false;
      view->repaint();
      return true;
    }
    if (k == FL_Up && n) {
      view->selected = std::max(0, view->selected - 1);
      view->show_password = false;
      view->repaint();
      return true;
    }
    if ((k == FL_Enter || k == FL_KP_Enter) && selected_entry()) {
      edit_entry();
      return true;
    }
    if ((k == FL_Delete || k == FL_BackSpace) && selected_entry()) {
      delete_entry();
      return true;
    }
    return false;
  }
  // Los atajos (como en KeePass): ⌘B usuario, ⌘C contraseña, ⌘L bloquear, ⌘S guardar, ⌘F buscar, ⌘N nueva.
  static int dispatch(int e, Fl_Window* w) {
    Form1* f = self();
    if (f && (e == FL_PUSH || e == FL_KEYBOARD || e == FL_MOUSEWHEEL)) f->last_touch = kp::now_s();
    if (f && (e == FL_KEYBOARD || e == FL_SHORTCUT) && (Fl::event_state() & FL_COMMAND) && f->shortcut(Fl::event_key())) return 1;
    return Fl::handle_(e, w);
  }
  bool shortcut(int k) {
    bool in_text = Fl::focus() && dynamic_cast<Fl_Input_*>(Fl::focus()) != nullptr;
    if (k == 'l') {
      lock();
      return unlocked == false;
    }
    if (!unlocked) return false;
    if (k == 's') return save(), true;
    if (k == 'f') {
      Search->take_focus();
      return true;
    }
    if (k == 'n') return add_entry(), true;
    if (k == 'e') return edit_entry(), true;
    if (k == 'b' && !in_text) return copy_field("UserName"), true;
    if (k == 'c' && !in_text && selected_entry()) return copy_field("Password"), true;
    return false;
  }
  void search_changed() {
    search = Search->value();
    view->auditing = false;
    view->selected = -1;
    view->list_scroll = 0;
    refresh();
    if (Fl::event() == FL_KEYBOARD && (Fl::event_key() == FL_Enter || Fl::event_key() == FL_KP_Enter) && !view->list.empty()) {
      view->selected = 0;
      Fl::focus(view);
      view->repaint();
    }
  }

  // ---- eventos del diseño
  void BtnUnlock_click() override { unlock(); }
  void Master_enter() override { unlock(); }
  void BtnAdd_click() override { add_entry(); }
  void BtnGen_click() override { generator(false); }
  void BtnLock_click() override { lock(); }
  void BtnSave_click() override { save(); }
  void Tick_timer() override {
    double now = kp::now_s();
    // El portapapeles, vacío otra vez.
    if (clip_until > 0 && now > clip_until) {
      copy("");
      clip_until = 0;
      say(tx::CLIP_CLEARED);
    }
    // Bloqueo solo tras unos minutos sin tocar nada (guardando antes si hay cambios).
    if (unlocked && now - last_touch > lock_minutes * 60.0) {
      if (dirty) save();
      lock_now(true);
      say(tx::AUTO_LOCKED);
    }
    if (!message.empty() && now > message_until) {
      message.clear();
      refresh();
    }
  }
  void Menu1_click(const std::string& item) override {
    last_touch = kp::now_s();
    if (item == tx::MP_NEW) create_db();
    else if (item == tx::MP_OPEN) open_other();
    else if (item == tx::MP_SAVE) save();
    else if (item == tx::MP_SAVE_AS) save_as();
    else if (item == tx::MP_LOCK) lock();
    else if (item == tx::MP_CLOSE) {
      if (ask_unsaved()) {
        lock_now(false);
        path.clear();
        save_settings();
        refresh();
      }
    } else if (item == tx::MP_QUIT) {
      if (can_close()) close_now();
    } else if (item == tx::MP_NEW_ENTRY) add_entry();
    else if (item == tx::MP_NEW_GROUP) new_group();
    else if (item == tx::MP_EDIT) edit_entry();
    else if (item == tx::MP_DELETE) delete_entry();
    else if (item == tx::MP_COPY_USER) copy_field("UserName");
    else if (item == tx::MP_COPY_PASS) copy_field("Password");
    else if (item == tx::MP_OPEN_URL) open_entry_url();
    else if (item == tx::MP_GENERATOR) generator(false);
    else if (item == tx::MP_AUDIT) act(11, -1);
    else if (item == tx::MP_MASTER) change_master();
    else if (item == tx::MP_SECURITY) security();
    else if (item == tx::MP_HOW) fl_message("%s", tx::HOW_TEXT);
    else if (item == tx::MP_ABOUT) fl_message("%s", tx::ABOUT_TEXT);
  }

  // ---- capturas y pruebas sin ventana
  void render_to(const std::string& file) {
    Fl_Image_Surface surf(w(), h(), 0);
    Fl_Surface_Device::push_current(&surf);
    fl_color(color());
    fl_rectf(0, 0, w(), h());
    for (int i = 0; i < children(); i++) {
      Fl_Widget* c = child(i);
      if (c->visible()) surf.draw(c, c->x(), c->y());
    }
    Fl_RGB_Image* img = surf.image();
    Fl_Surface_Device::pop_current();
    if (!file.empty()) fl_write_png(file.c_str(), img);
    delete img;
  }
  // Una bóveda de ejemplo (inventada; nada de verdad).
  void demo_vault() {
    kp::new_database(db, tx::DEMO_DB);
    kp::Node* root = kp::root_group(db);
    struct E {
      int group;
      const char *title, *user, *pass, *url, *notes;
    };
    std::vector<kp::Node*> gs;
    for (const char* g : {tx::G_EMAIL, tx::G_BANKING, tx::G_WORK, tx::G_SOCIAL}) gs.push_back(kp::new_group(root, g));
    const E list[] = {
        {0, tx::DEMO_E1, "ana.garcia@ejemplo.es", "vN8#qL2!zR7@wK4$", "https://correo.ejemplo.es", tx::DEMO_N1},
        {0, tx::DEMO_E2, "ana.trabajo@ejemplo.es", "1234", "https://webmail.ejemplo.es", ""},
        {1, tx::DEMO_E3, "12345678Z", "Tq9%Hm3^Xc6&Lp1*", "https://banco.ejemplo.es", tx::DEMO_N3},
        {1, tx::DEMO_E4, "ana.garcia", "sol2015", "https://tarjeta.ejemplo.es", ""},
        {2, tx::DEMO_E5, "agarcia", "Rr4!Jd8@Kv2#Ns6%", "https://vpn.empresa.ejemplo", tx::DEMO_N5},
        {2, tx::DEMO_E6, "ana", "sol2015", "https://intranet.empresa.ejemplo", ""},
        {3, tx::DEMO_E7, "@ana_garcia", "Bf7$Wn3!Pq9&Ht2^", "https://social.ejemplo", ""},
        {-1, tx::DEMO_E8, "ana", "Mk3#Zt8!Qv5@Lc1$", "", tx::DEMO_N8},
    };
    for (const auto& d : list) {
      kp::Node* e = kp::new_entry(db, d.group < 0 ? root : gs[(size_t)d.group]);
      kp::set_field(db, e, "Title", d.title);
      kp::set_field(db, e, "UserName", d.user);
      kp::set_field(db, e, "Password", d.pass);
      kp::set_field(db, e, "URL", d.url);
      kp::set_field(db, e, "Notes", d.notes);
    }
    // Una entrada con historial y otra que lleva años sin cambiar.
    kp::Node* bank = kp::entries(gs[1])[0];
    kp::backup(db, bank);
    kp::Node* old = kp::entries(gs[1])[1];
    old->child("Times")->set("LastModificationTime", kp::kdbx_time(kp::unix_now() - 800LL * 86400));
    master_key = kp::composite_key("demo", kp::Bytes());
    unlocked = true;
    view->mode = kp::M_VAULT;
    cur_group = gs[1];
    path = kp::config_dir() + "/Personal.kdbx";
  }
  void demo_state(int W, int H) {
    Fl::screen_count();
    demo = true;
    setup();
    size(W, H);
    copy = [](const std::string&) {};
    open_url = [](const std::string&) {};
    refresh();
  }
  int shots(const std::string& dir) {
    fl_make_path(dir.c_str());
    demo_state(1100, 700);
    path = "Personal.kdbx";
    view->mode = kp::M_WELCOME;
    refresh();
    render_to(dir + "/welcome.png");
    view->mode = kp::M_LOCKED;
    refresh();
    render_to(dir + "/lock.png");
    demo_vault();
    refresh();
    view->selected = 0;
    refresh();
    render_to(dir + "/vault.png");
    view->show_password = true;
    view->repaint();
    render_to(dir + "/shown.png");
    view->show_password = false;
    act(11, -1);
    view->selected = 0;
    view->repaint();
    render_to(dir + "/audit.png");
    // Los diálogos, dibujados sin enseñarse.
    kp::dialog_shot() = dir + "/generator.png";
    kp::GeneratorWin g;
    g.run(true);
    kp::dialog_shot() = dir + "/entry.png";
    kp::EntryForm f;
    f.title = tx::DEMO_E3;
    f.user = "12345678Z";
    f.pass = "Tq9%Hm3^Xc6&Lp1*";
    f.url = "https://banco.ejemplo.es";
    f.notes = tx::DEMO_N3;
    group_choices(f, kp::root_group(db));
    kp::entry_dialog(f, false);
    kp::dialog_shot() = dir + "/newdb.png";
    kp::DbForm nf;
    nf.name = tx::DEMO_DB;
    kp::db_dialog(nf, tx::NEW_DB_TITLE);
    kp::dialog_shot().clear();
    std::printf("shots ok %s\n", dir.c_str());
    return 0;
  }
  int ui_test() {
    demo_state(1100, 700);
    int f = 0;
    auto chk = [&](bool ok, const char* what) {
      if (fl_getenv("DMS_PASS_TRACE")) std::printf("ok? %d %s\n", ok ? 1 : 0, what);
      if (!ok) {
        std::printf("FAIL %s\n", what);
        f++;
      }
    };
    std::string dir = kp::config_dir() + "/prueba-ui";
    fl_make_path(dir.c_str());
    std::string file = dir + "/Pruebas.kdbx";
    std::remove(file.c_str());
    std::remove((dir + "/Pruebas.keyx").c_str());
    // La bienvenida: crear o abrir.
    render_to("");
    int create = 0, open = 0;
    for (const auto& h : view->hits) {
      create += h.act == 1;
      open += h.act == 2;
    }
    chk(view->mode == kp::M_WELCOME && create == 1 && open == 1 && !Top->visible(), "la bienvenida: crear o abrir");
    // Crear una base de datos (con la contraseña repetida mal, primero).
    int asked = 0;
    db_form = [&asked](kp::DbForm& d, const char*) {
      asked++;
      d.name = "Pruebas";
      d.pass = "Prueba-Larga-2026!";
      d.pass2 = asked == 1 ? "otra" : "Prueba-Larga-2026!";
      d.cipher = 1;
      d.kdf = 1;
      return true;
    };
    pick_save = [file] { return file; };
    for (const auto& h : view->hits)
      if (h.act == 1) {
        Fl::e_x = h.x + 5;
        Fl::e_y = h.y + 5;
        view->handle(FL_PUSH);
        break;
      }
    kp::Bytes raw;
    bool written = read_bytes(file, raw);
    chk(asked == 2 && view->mode == kp::M_VAULT && unlocked && !dirty && written && raw.size() > 200 && Top->visible() &&
            kp::root_group(db)->get("Name") == "Pruebas" && view->rows.size() == 5 && db.cipher == kp::C_CHACHA && db.kdf.type == kp::K_ARGON2ID,
        "crear: repite la contraseña, la guarda y la abre (ChaCha20 + Argon2id)");
    // Una entrada nueva (con la contraseña generada de partida).
    std::string offered;
    entry_form = [&offered](kp::EntryForm& e, bool is_new) {
      offered = e.pass;
      e.title = "Correo";
      e.user = "ana@ejemplo.es";
      e.url = "correo.ejemplo.es";
      e.notes = "nota";
      return is_new;
    };
    BtnAdd_click();
    kp::Node* e = selected_entry();
    chk(e && kp::field(e, "Title") == "Correo" && kp::field(e, "Password") == offered && offered.size() == 20 && dirty &&
            std::string(BtnSave->label()) == tx::SAVE_DIRTY,
        "añadir una entrada (con una contraseña fuerte de partida)");
    BtnSave_click();
    chk(!dirty, "guardar");
    // Copiar: el portapapeles se vacía solo.
    std::vector<std::string> clip;
    copy = [&clip](const std::string& s) { clip.push_back(s); };
    render_to("");
    for (const auto& h : view->hits)
      if (h.act == 31) {
        Fl::e_x = h.x + 5;
        Fl::e_y = h.y + 5;
        view->handle(FL_PUSH);
        break;
      }
    bool copied = clip.size() == 1 && clip[0] == offered;
    clip_until = kp::now_s() - 1;
    Tick_timer();
    chk(copied && clip.size() == 2 && clip[1].empty(), "copiar la contraseña y vaciar el portapapeles");
    std::string opened;
    open_url = [&opened](const std::string& u) { opened = u; };
    act(33, -1);
    chk(opened == "https://correo.ejemplo.es", "abrir la URL (con https://)");
    // Bloquear y desbloquear: mal y bien.
    BtnLock_click();
    chk(view->mode == kp::M_LOCKED && !unlocked && master_key.empty() && !db.xml && Master->visible() && clip.back().empty(), "bloquear: no queda nada en memoria");
    Master->value("mala");
    BtnUnlock_click();
    bool wrong = !unlocked && view->error == tx::ERR_KEY && std::string(Master->value()).empty();
    Master->value("Prueba-Larga-2026!");
    Master_enter();
    chk(wrong && unlocked && view->mode == kp::M_VAULT && view->error.empty(), "desbloquear: la contraseña mala no, la buena sí");
    // Editar: la versión de antes, al historial.
    act(10, 0);
    for (int i = 0; i < (int)group_nodes.size(); i++)
      for (kp::Node* n : kp::entries(group_nodes[(size_t)i]))
        if (kp::field(n, "Title") == "Correo") {
          act(10, i);
          act(20, 0);
        }
    entry_form = [](kp::EntryForm& x, bool) {
      x.pass = "1234";
      x.group = 2;
      return true;
    };
    act(35, -1);
    e = nullptr;
    std::vector<kp::Node*> all;
    kp::collect(db, kp::root_group(db), all);
    for (kp::Node* n : all)
      if (kp::field(n, "Title") == "Correo") e = n;
    chk(e && kp::field(e, "Password") == "1234" && e->child("History")->kids.size() == 1 && e->parent == view->rows[2].g && dirty,
        "editar: al historial y a otro grupo");
    // La revisión de seguridad: una débil y repetida.
    entry_form = [](kp::EntryForm& x, bool) {
      x.title = "Copia";
      x.pass = "1234";
      return true;
    };
    BtnAdd_click();
    act(11, -1);
    chk(view->auditing && view->audit_count >= 2 && view->list.size() == (size_t)view->audit_count && (view->findings[0].issues & kp::I_REUSED),
        "la revisión de seguridad");
    // Buscar.
    Search->value("corr");
    search_changed();
    chk(view->searching && view->list.size() == 1 && kp::field(view->list[0], "Title") == "Correo", "buscar");
    Search->value("");
    search_changed();
    // Teclas: bajar y copiar el usuario con ⌘B.
    act(10, 0);
    kp::Node* g2 = view->rows[2].g;
    for (int i = 0; i < (int)group_nodes.size(); i++)
      if (group_nodes[(size_t)i] == g2) act(10, i);
    view->selected = -1;
    key(FL_Down);
    clip.clear();
    shortcut('b');
    chk(view->selected == 0 && clip.size() == 1 && clip[0] == "ana@ejemplo.es", "teclas: bajar y ⌘B copia el usuario");
    // Borrar: a la papelera; desde ella, para siempre.
    confirm = [](const std::string&) { return true; };
    delete_entry();
    kp::Node* bin = kp::recycle_bin(db, false);
    chk(bin && kp::entries(bin).size() == 1, "borrar: a la papelera");
    // Un grupo nuevo y cambiarle el nombre.
    ask_text = [](const std::string&, const std::string&) { return std::string("Viajes"); };
    new_group();
    bool made = cur_group && cur_group->get("Name") == "Viajes";
    int vi = -1;
    for (int i = 0; i < (int)group_nodes.size(); i++)
      if (group_nodes[(size_t)i] == cur_group) vi = i;
    choose = [](const std::vector<std::string>&) { return 1; };
    ask_text = [](const std::string&, const std::string&) { return std::string("Vacaciones"); };
    group_menu(vi);
    chk(made && cur_group->get("Name") == "Vacaciones", "grupos: crear y cambiar el nombre");
    // El generador.
    std::string gen;
    gen_dialog = [&gen](bool) {
      kp::GenOptions o;
      o.length = 32;
      gen = kp::generate(o);
      return "copy:" + gen;
    };
    clip.clear();
    BtnGen_click();
    chk(gen.size() == 32 && clip.size() == 1 && clip[0] == gen, "el generador: copiar");
    // Bloqueo solo con cambios: se guarda antes.
    bool was_dirty = dirty;
    last_touch = kp::now_s() - lock_minutes * 60 - 5;
    Tick_timer();
    chk(was_dirty && !unlocked && view->mode == kp::M_LOCKED, "bloqueo por inactividad (guardando antes)");
    Master->value("Prueba-Larga-2026!");
    unlock();
    bool kept = false;
    std::vector<kp::Node*> again;
    kp::collect(db, kp::root_group(db), again);
    for (kp::Node* n : again) kept = kept || kp::field(n, "Title") == "Copia";
    chk(unlocked && kept, "lo guardado al bloquear sigue ahí");
    // Cambiar la clave maestra a contraseña + archivo de clave.
    db_form = [](kp::DbForm& d, const char*) {
      d.pass = d.pass2 = "Nueva-Clave-Maestra-9";
      d.keyfile = true;
      return true;
    };
    change_master();
    chk(!dirty && !keyfile_path.empty() && kp::file_exists(keyfile_path), "cambiar la clave maestra (con archivo de clave)");
    std::string kfp = keyfile_path;
    lock_now(true);
    keyfile_path.clear();
    Master->value("Nueva-Clave-Maestra-9");
    unlock();
    bool needs_kf = !unlocked && view->error == tx::ERR_KEY;
    keyfile_path = kfp;
    Master->value("Nueva-Clave-Maestra-9");
    unlock();
    chk(needs_kf && unlocked, "sin el archivo de clave no abre; con él, sí");
    // La seguridad de la base de datos: a AES-256 + AES-KDF.
    db_form = [](kp::DbForm& d, const char*) {
      d.cipher = 0;
      d.kdf = 2;
      return true;
    };
    security();
    save();
    lock_now(true);
    Master->value("Nueva-Clave-Maestra-9");
    unlock();
    chk(unlocked && db.cipher == kp::C_AES && db.kdf.type == kp::K_AESKDF, "cambiar el cifrado y la derivación");
    // Abrir otra: pide guardar si hay cambios.
    entry_form = [](kp::EntryForm& x, bool) {
      x.title = "Sin guardar";
      return true;
    };
    BtnAdd_click();
    int asked_save = 0;
    ask_save = [&asked_save](const std::string&) {
      asked_save++;
      return 0;
    };
    pick_open = [] { return std::string(); };
    open_other();
    chk(asked_save == 1 && unlocked && dirty, "abrir otra con cambios: pregunta (y cancelar no cierra)");
    if (!f) std::printf("uitest ok\n");
    return f ? 1 : 0;
  }
};
''';
