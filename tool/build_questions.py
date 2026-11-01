"""Builds assets/questions/questions.json from tool/question_source.py.

Run from the project root:  python tool/build_questions.py
The app's QuestionBank validation is the real gate; this script only does
the mechanical work and a few early sanity checks.
"""
import hashlib
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).parent))
import question_source as src  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / 'assets' / 'questions' / 'questions.json'


def answer_position(question_id: str) -> int:
    """Stable 0-3 slot for the correct answer, spread evenly by ID hash."""
    return int(hashlib.sha256(question_id.encode()).hexdigest(), 16) % 4


def main() -> None:
    previous = json.loads(OUT.read_text(encoding='utf-8'))
    originals = {q['id']: q for q in previous['questions'] if q['id'] in src.ORIGINAL_TOPICS}
    missing = set(src.ORIGINAL_TOPICS) - set(originals)
    if missing:
        sys.exit(f'Original questions missing: {sorted(missing)}')

    questions = []
    for qid, topic in src.ORIGINAL_TOPICS.items():
        questions.append({**originals[qid], 'topic': topic})

    for qid, topic, prompt, correct, *rest in src.NEW:
        wrong, explanation = rest[:3], rest[3]
        slot = answer_position(qid)
        options = list(wrong)
        options.insert(slot, correct)
        category = next(c for t, c, _ in src.TOPICS if t == topic)
        questions.append({
            'id': qid,
            'category': category,
            'topic': topic,
            'prompt': prompt,
            'options': options,
            'correctIndex': slot,
            'explanation': explanation,
        })

    ids = [q['id'] for q in questions]
    if len(ids) != len(set(ids)):
        sys.exit('Duplicate question IDs')

    bank = {
        'version': src.VERSION,
        'topics': [{'id': t, 'category': c, 'name': n} for t, c, n in src.TOPICS],
        'questions': questions,
    }
    OUT.write_text(json.dumps(bank, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

    counts = {}
    slots = [0, 0, 0, 0]
    for q in questions:
        counts[q['topic']] = counts.get(q['topic'], 0) + 1
        slots[q['correctIndex']] += 1
    print(f'{len(questions)} questions, version {src.VERSION}')
    for t, c, _ in src.TOPICS:
        print(f'  {c:6} {t:12} {counts.get(t, 0)}')
    print('  answer slots A-D:', slots)


if __name__ == '__main__':
    main()
