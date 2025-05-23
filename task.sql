CREATE TABLE students (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    age INTEGER,
    score INTEGER,
    department_id INTEGER REFERENCES departments(id)
);

CREATE TABLE departments (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE course_enrollments (
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id),
    course_title VARCHAR(50),
    enrolled_on DATE
);


INSERT INTO departments (name) VALUES
('CSE'), 
('EEE'), 
('BBA');

INSERT INTO students (name, age, score, department_id) VALUES
('Alice', 20, 85, 1),
('Bob', 22, 92, 1),
('Charlie', 19, 75, 2),
('Diana', 21, 90, 2),
('Eve', 23, NULL, 3),
('Frank', 20, 60, 3),
('Grace', 24, 95, 1);

INSERT INTO course_enrollments (student_id, course_title, enrolled_on) VALUES
(1, 'Database Systems', '2025-01-12'),
(2, 'Operating Systems', '2025-01-15'),
(3, 'Microprocessors', '2025-01-20'),
(4, 'Digital Logic Design', '2025-01-18'),
(1, 'Web Development', '2025-02-01'),
(6, 'Business Ethics', '2025-02-05');


SELECT * FROM departments;
SELECT * FROM students;
SELECT * FROM course_enrollments;

-- TASK 1. Retrieve all students who scored higher than the average score.

SELECT * FROM students WHERE score > (SELECT AVG(score) FROM students);

-- TASK 2. Find students whose age is greater than the average age of all students.
SELECT * FROM students WHERE age > (SELECT avg(age) FROM students);

-- TASK 3. Get names of students who are enrolled in any course (use IN with subquery).
SELECT * FROM students
WHERE id IN (SELECT student_id FROM course_enrollments)

-- TASK 4. Retrieve departments with at least one student scoring above 90 (use EXISTS).
SELECT * FROM departments d
WHERE EXISTS(
    SELECT 1 FROM students s WHERE s.department_id = d.id AND s.score > 90
);
-- Chat GPT

-- TASK 5. Create a view to show each student’s name, department, and score.
CREATE OR REPLACE VIEW show_student_info AS
SELECT s.name, d.name as department_name, score  FROM students s
INNER JOIN departments d ON s.department_id = d.id;

SELECT * FROM show_student_info;

-- TASK 6. Create a view that lists all students enrolled in any course with the enrollment date.
CREATE OR REPLACE VIEW student_with_course AS
SELECT name, age, course_title, enrolled_on, score FROM course_enrollments c
JOIN students s ON c.student_id = s.id;

SELECT * FROM student_with_course;

-- TASK 7. Create a function that takes a student's score and returns a grade (e.g., A, B, C, F).
CREATE FUNCTION get_student_grade(score INTEGER)
RETURNS TEXT
LANGUAGE plpgsql
AS
$$
BEGIN
    IF score >= 90 THEN
        RETURN 'A';
    ELSEIF score >= 80 THEN
        RETURN 'B';
    ELSEIF score >= 70 THEN
        RETURN 'C';
    ELSE 
        RETURN 'F';
    END IF;
END;
$$

SELECT get_student_grade(45);

-- TASK 8. Create a function that returns the full name and department of a student by ID.
CREATE OR REPLACE FUNCTION get_student_info_by_id(s_id INTEGER)
RETURNS TABLE(student_name VARCHAR(50), department_name VARCHAR(50))
LANGUAGE plpgsql AS
$$
    BEGIN
        RETURN QUERY
        SELECT s.name as student_name, d.name as department_name FROM students s 
        JOIN departments d ON s.department_id = d.id WHERE s.id = s_id;
    END;
$$

SELECT * FROM get_student_info_by_id(1);

-- TASK 9. Write a stored procedure to update a student's department.
CREATE PROCEDURE update_student_department(s_id INT, s_department_id INT)
LANGUAGE plpgsql
AS
$$
BEGIN
    UPDATE students SET department_id = s_department_id WHERE id = s_id;
END;
$$

CALL update_student_department(1, 2);

-- TASK 10. Write a procedure to delete students who haven't enrolled in any course.
CREATE PROCEDURE not_enrolled_user_delete()
LANGUAGE plpgsql AS
$$
BEGIN
    DELETE FROM students WHERE id IN(
        SELECT s.id FROM students s
        LEFT OUTER JOIN course_enrollments c on s.id = c.student_id WHERE c.course_title IS NULL
    );
END;
$$

CALL not_enrolled_user_delete();

-- 11. Create a trigger that automatically logs enrollment when a student is added to course_enrollments.
CREATE Table enrolled_student_logs(
    id SERIAL PRIMARY KEY,
    student_id INTEGER REFERENCES students(id),
    course_title VARCHAR(50),
    enrolled_on DATE,
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE FUNCTION enrolled_log_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
    BEGIN
        INSERT INTO enrolled_student_logs (student_id, course_title, enrolled_on) VALUES
        (NEW.student_id, NEW.course_title, NEW.enrolled_on);
        RETURN NEW;
    END
$$

CREATE TRIGGER enrolled_log
AFTER INSERT ON course_enrollments
FOR EACH ROW  
EXECUTE FUNCTION enrolled_log_trigger();

INSERT INTO course_enrollments (student_id, course_title, enrolled_on) VALUES (2, 'Web Development', '2025-03-09');

SELECT * FROM enrolled_student_logs;
SELECT * FROM course_enrollments;

-- TASK 12. Add a trigger that sets the score to 0 if a new student record is added without a score.
CREATE FUNCTION set_score_trigger_func()
RETURNS TRIGGER
LANGUAGE plpgsql AS
$$
BEGIN
    UPDATE students SET score = 0 WHERE id = NEW.id;
    RETURN NEW;
END
$$

CREATE TRIGGER set_score_trigger
AFTER INSERT ON students
FOR EACH ROW
EXECUTE FUNCTION set_score_trigger_func();

INSERT INTO students (name, age, department_id) VALUES
('Obidy Hasan', 23, 2);

SELECT * FROM students;

-- 13. Add an index to the score column in the students table.
CREATE INDEX idx_students_score
ON students(score);

-- TASK 14. Add a composite index on student_id and enrolled_on in the course_enrollments table.
CREATE INDEX idx_course_enrollments_data
ON course_enrollments (student_id, enrolled_on);

EXPLAIN ANALYSE
SELECT * FROM course_enrollments WHERE student_id = 3 AND enrolled_on = '2025-01-20';

-- TASK 15. Compare query performance with and without indexes using EXPLAIN.