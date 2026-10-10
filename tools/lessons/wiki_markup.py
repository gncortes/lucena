"""A marcação dos nomes nas falas das aulas: `{{texto visível|chave}}` (a chave
aponta a página da Wikipedia em `assets/lessons/links.json`). Para conferir,
contar ou ler o texto, só o texto visível conta: `plain` tira a marcação."""
import re

MARK = re.compile(r'\{\{([^{}|]+)\|([^{}|]+)\}\}')


def plain(text):
    """O texto como aparece no app e como a voz lê."""
    return MARK.sub(lambda m: m.group(1), text) if isinstance(text, str) else text


def plain_texts(texts):
    """Um arquivo de falas (`{"chave": "fala"}` ou listas) sem a marcação."""
    return {key: [plain(t) for t in value] if isinstance(value, list) else plain(value)
            for key, value in texts.items()}


def keys(text):
    """As chaves usadas em `text`."""
    return [m.group(2).strip() for m in MARK.finditer(text)] if isinstance(text, str) else []
