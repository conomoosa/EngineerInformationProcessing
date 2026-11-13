--학생 테이블 생성
CREATE TABLE IF NOT EXISTS Student 
(
    ID INTEGER PRIMARY KEY,
    NAME TEXT NOT NULL,
    AGE INTEGER,
    SCORE INTEGER
);

-- 데이터 입력
INSERT INTO Student 
(
    ID, 
    NAME, 
    AGE, 
    SCORE
)
VALUES  
(
    1, 
    '홍길동', 
    25, 
    90
),
(
    2, 
    '김철수', 
    23, 
    85
),
(
    3, 
    '이영희', 
    24, 
    95
);