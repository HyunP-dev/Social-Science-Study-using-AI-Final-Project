from transformers import TextClassificationPipeline, BertForSequenceClassification, AutoTokenizer
import pandas as pd

model_name = 'smilegate-ai/kor_unsmile'
model = BertForSequenceClassification.from_pretrained(model_name)
tokenizer = AutoTokenizer.from_pretrained(model_name)
pipe = TextClassificationPipeline(
    model = model,
    tokenizer = tokenizer,
    device = -1,   # cpu: -1, gpu: gpu number
    return_all_scores = True,
    function_to_apply = 'sigmoid'
)   

def text_classify(texts):
    results = map(lambda e: {
        row['label']: row['score'] for row in e
    }, pipe(texts))
    return pd.DataFrame(results)