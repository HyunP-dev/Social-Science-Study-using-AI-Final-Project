# Social Science Study using AI Final Project


## Summary
본 프로젝트에서는 네이트 뉴스를 크롤링하여 최근 n년 간 업로드된 기사에 달린 댓글들을 Smilegate AI에서 공개한 [Korean UnSmile Dataset](https://github.com/smilegate-ai/korean_unsmile_dataset)로 부터 학습한 인공지능 모델을 이용해 분류하여 댓글 상에 나타난 혐오 표현의 양상에 대하여 여러가지 시계열 모형을 이용해 분석하고자 한다.


## Files Tree
```
.
├── databases                : 데이터베이스
│   └── natenews.sqlite      : 수집한 데이터들을 저장한 데이터베이스
├── docker.readme            : NVIDIA Docker 관련 명령어를 적어둔 쪽지
├── README.md                : 본 파일
├── reports                  : 발표 자료
│   ├── images               : 발표자료에 쓰일 이미지들을 모아둔 폴더
│   ├── presentation.pdf     : tex 파일을 컴파일한 결과물
│   └── presentation.tex     : 발표용 TeX 파일
└── scripts                  : 프로젝트를 진행하며 작성한 코드
    ├── analyze.r            : 수집한 데이터를 이용해 여러 분석을 수행하는 코드
    ├── docker_server.py     : R과 통신하기 위한 Docker에서 쓸 서버 코드
    ├── model.py             : Korean UnSmile Dataset 의 인공지능 모델
    ├── natenews.r           : nate 뉴스를 수집할 때 사용할 함수들을 정의한 코드
    ├── scrap.r              : nate 뉴스를 수집하고 DB에 저장하는 코드
    └── sentiment_analyzer.r : docker에 열린 서버를 이용해 감정 분석을 해주는 코드
```