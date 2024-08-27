-- comp9311 23T2 Project 1

-- Q1:
create or replace view q1(subject_code)
as
select subjects.code as subject_code
from subjects
join orgunits on subjects.offeredby = orgunits.id
join orgunit_types on orgunits.utype = orgunit_types.id
where orgunit_types.name = 'Centre';


--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q2:
create or replace view q2(course_id)
as
select courses.id as course_id
from courses
join classes as classes_all on courses.id = classes_all.course
join class_types as types_all on classes_all.ctype = types_all.id
join classes as classes_seminar on courses.id = classes_seminar.course
join class_types as types_seminar on classes_seminar.ctype = types_seminar.id
where types_seminar.name = 'Seminar'
group by courses.id
having count(distinct types_all.name) >= 4;


--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q3:
create or replace view q3(unsw_id)
as
select people.unswid as unsw_id
from people
join students on people.id = students.id
join course_enrolments on students.id = course_enrolments.student
join courses on course_enrolments.course = courses.id
join semesters on courses.semester = semesters.id
join subjects on courses.subject = subjects.id
where semesters.year = 2010
and (subjects._equivalent like '%JURD%' and subjects._equivalent like '%LAWS%')
group by people.unswid
having count(distinct courses.id) >= 2;


--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q4:
create or replace view Q4(course_id, avg_mark)
as
select courses.id as course_id, round(avg(course_enrolments.mark), 4) as avg_mark
from courses
join subjects on courses.subject = subjects.id
join course_enrolments on courses.id = course_enrolments.course
join semesters on courses.semester = semesters.id
where subjects.code like 'COMP%'
and semesters.year = 2010
and course_enrolments.mark is not null
group by courses.id
having round(avg(course_enrolments.mark), 4) = (
    select max(avg_mark) 
    from (
        select round(avg(course_enrolments.mark), 4) as avg_mark
        from courses
        join subjects on courses.subject = subjects.id
        join course_enrolments on courses.id = course_enrolments.course
        join semesters on courses.semester = semesters.id
        where subjects.code like 'COMP%'
        and semesters.year = 2010
        and course_enrolments.mark is not null
        group by courses.id
    ) as sub_query
);

--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q5:
create or replace view q5(faculty_id, room_id)
as
select subquery1.faculty_id, subquery1.room_id
from
(
  select
    orgunits.id as faculty_id,
    rooms.id as room_id,
    count(*) as tutorial_count
  from
    orgunits
    join subjects on subjects.offeredby = orgunits.id
    join courses on courses.subject = subjects.id
    join classes on classes.course = courses.id
    join class_types on class_types.id = classes.ctype
    join rooms on rooms.id = classes.room
    join orgunit_types on orgunit_types.id = orgunits.utype
  where
    orgunit_types.name like '%Faculty%'
    and class_types.name = 'Tutorial'
    and extract(year from classes.startdate) = 2005
  group by
    orgunits.id, rooms.id
) as subquery1
inner join 
(
  select subquery2.faculty_id, max(subquery2.tutorial_count) as max_tutorial_count
  from 
  (
    select
      orgunits.id as faculty_id,
      rooms.id as room_id,
      count(*) as tutorial_count
    from
      orgunits
      join subjects on subjects.offeredby = orgunits.id
      join courses on courses.subject = subjects.id
      join classes on classes.course = courses.id
      join class_types on class_types.id = classes.ctype
      join rooms on rooms.id = classes.room
      join orgunit_types on orgunit_types.id = orgunits.utype
    where
      orgunit_types.name like '%Faculty%'
      and class_types.name = 'Tutorial'
      and extract(year from classes.startdate) = 2005
    group by
      orgunits.id, rooms.id
  ) as subquery2
  group by subquery2.faculty_id
) as subquery3
on subquery1.faculty_id = subquery3.faculty_id
where subquery1.tutorial_count = subquery3.max_tutorial_count;


--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q6:
CREATE OR REPLACE VIEW Q6_step1(program_id, stream_id, max_enrolment_count)
AS
SELECT
  program_enrolments.program AS program_id,
  stream_enrolments.stream AS stream_id,
  COUNT(*) AS enrolment_count
FROM
  public.program_enrolments
  JOIN public.stream_enrolments ON program_enrolments.id = stream_enrolments.partof
  JOIN public.programs ON programs.id = program_enrolments.program
  JOIN public.orgunits ON programs.offeredby = orgunits.id
  JOIN public.semesters ON program_enrolments.semester = semesters.id
WHERE
  orgunits.name = 'Faculty of Arts and Social Sciences'
  AND semesters.year = 2005
  AND semesters.term = 'S1'
GROUP BY
  program_enrolments.program,
  stream_enrolments.stream;

create or replace view Q6(program_id, stream_id)
as
SELECT 
    program_id, 
    stream_id
FROM 
    Q6_step1
WHERE 
    max_enrolment_count = (SELECT MAX(max_enrolment_count) 
                           FROM Q6_step1 as s1 
                           WHERE s1.program_id = Q6_step1.program_id);


--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q7:
create or replace view q7 as
select 
  subjects.id as subject_id,
  people.name as staff_name
from 
  public.subjects
join 
  public.orgunits on subjects.offeredby = orgunits.id
join
  public.courses on courses.subject = subjects.id
join
  public.semesters on courses.semester = semesters.id
join
  public.course_staff on course_staff.course = courses.id
join
  public.people on course_staff.staff = people.id
where 
  orgunits.name ilike '%law%'
  and semesters.year = 2008
  and not exists (
    select 1 from public.courses as other_courses
    where other_courses.subject = subjects.id
    and other_courses.semester in (select id from public.semesters where year = 2008)
    and not exists (
      select 1 from public.course_staff as other_course_staff
      where other_course_staff.course = other_courses.id and other_course_staff.staff = course_staff.staff
    )
  )
group by
  subjects.id,
  people.name
having
  count(distinct courses.id) >= 2;

--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q8:
CREATE INDEX idx_students_id ON students (id);
CREATE INDEX idx_people_id ON people (id);
CREATE INDEX idx_program_enrolments_program ON program_enrolments (program);
CREATE INDEX idx_programs_id ON programs (id);
CREATE INDEX idx_people_unswid ON people (unswid);
CREATE INDEX idx_program_enrolments_student ON program_enrolments (student);
CREATE INDEX idx_program_enrolments_semester ON program_enrolments (semester);
CREATE INDEX idx_courses_id ON courses (id);
CREATE INDEX idx_courses_subject ON courses (subject);
CREATE INDEX idx_subjects_id ON subjects (id);
CREATE INDEX idx_orgunits_id ON orgunits (id);
CREATE INDEX idx_course_enrolments_student ON course_enrolments (student);
CREATE INDEX idx_course_enrolments_course ON course_enrolments (course);
CREATE INDEX idx_course_enrolments_mark ON course_enrolments (mark);

-- Create a view for course enrolments count
CREATE OR REPLACE VIEW course_enrolments_count AS
SELECT
    course_enrolments.course AS course_id,
    COUNT(DISTINCT course_enrolments.student) AS student_count
FROM course_enrolments
GROUP BY course_enrolments.course;

-- Modify all_info to include the student count for each course
CREATE OR REPLACE VIEW all_info AS
SELECT
    people.unswid,
    students.id AS student_id,
    people.name,
    program_enrolments.program,
    program_enrolments.semester AS program_enrolments_semester,
    course_enrolments.course AS course_id,
    courses.semester AS courses_semester,
    subjects.code,
    course_enrolments.mark,
    orgunits.longname,
    orgunits.id AS orgunit_id,
    programs.offeredby,
    course_enrolments_count.student_count,
    rank(*) OVER (
        PARTITION BY course_enrolments.course
        ORDER BY COALESCE(course_enrolments.mark, 0) DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS rank
FROM people
JOIN students ON students.id = people.id
JOIN program_enrolments ON program_enrolments.student = students.id
JOIN programs ON programs.id = program_enrolments.program
JOIN orgunits ON orgunits.id = programs.offeredby
JOIN course_enrolments ON students.id = course_enrolments.student
JOIN courses ON courses.id = course_enrolments.course
JOIN subjects ON courses.subject = subjects.id
JOIN course_enrolments_count ON course_enrolments.course = course_enrolments_count.course_id
WHERE program_enrolments.semester = courses.semester;

-- Modify the other views to only include courses with more than 100 students
CREATE OR REPLACE VIEW top10_students_math_courses AS
SELECT *
FROM all_info
WHERE all_info.mark >= 1
AND all_info.rank <= 10
AND all_info.student_count > 100
AND all_info.code LIKE 'MATH%'
AND all_info.longname = 'Faculty of Science';

CREATE OR REPLACE VIEW top10_students_not_math_courses AS
SELECT *
FROM all_info
WHERE all_info.mark >= 1
AND all_info.rank <= 10
AND all_info.student_count > 100
AND all_info.code NOT LIKE 'MATH%'
AND all_info.longname = 'Faculty of Science';

-- Creating the view to unify the math and non-math top students
CREATE OR REPLACE VIEW top_students AS
SELECT
    unswid,
    name,
    'math' AS course_type
FROM top10_students_math_courses
UNION ALL
SELECT
    unswid,
    name,
    'not_math' AS course_type
FROM top10_students_not_math_courses;

-- Creating the final view
create or replace view Q8(unsw_id, name)
AS
SELECT DISTINCT math.unswid, math.name
FROM (
    SELECT unswid, name
    FROM top_students
    WHERE course_type = 'math'
) math
LEFT JOIN (
    SELECT unswid
    FROM top_students
    WHERE course_type = 'not_math'
) not_math
ON math.unswid = not_math.unswid
WHERE not_math.unswid IS NULL;




--... SQL statements, possibly using other views/functions defined by you ...
;

-- Q9:
--Select qualified professors
CREATE OR REPLACE VIEW ProfessorsView (prof_id) AS
SELECT DISTINCT People.id AS prof_id
FROM People
JOIN Affiliations ON People.id = Affiliations.staff
JOIN Staff_roles ON Affiliations.role = Staff_Roles.id
JOIN Orgunits ON Affiliations.orgunit = Orgunits.id
WHERE LOWER(Staff_Roles.name) LIKE '%professor%'
AND Orgunits.longname = 'School of Mechanical and Manufacturing Engineering';


CREATE OR REPLACE VIEW Q9(prof_id, fail_rate) AS
SELECT people.unswid AS prof_id,
       ROUND(CAST(COUNT(CASE WHEN course_enrolments.mark < 50 THEN 1 END) AS NUMERIC) / COUNT(course_enrolments.mark), 4) AS fail_rate
FROM ProfessorsView
JOIN course_staff ON course_staff.staff = ProfessorsView.prof_id
JOIN staff_roles ON course_staff.role = staff_roles.id
JOIN people ON ProfessorsView.prof_id = people.id
JOIN courses ON course_staff.course = courses.id
JOIN subjects ON courses.subject = subjects.id
JOIN course_enrolments ON courses.id = course_enrolments.course
WHERE staff_roles.name = 'Course Convenor' 
  AND subjects.career = 'UG'
  AND course_enrolments.mark IS NOT NULL
GROUP BY people.unswid;

--... SQL statements, possibly using other views/functions defined by you ...

;
-- Q10:

create or replace view enrolled_over_2000_days AS 
SELECT 
    people.unswid, 
    MIN(semesters.starting) AS starting_date, 
    MAX(semesters.ending) AS ending_date,
    (MAX(semesters.ending) - MIN(semesters.starting)) AS enrollment_duration
FROM 
    public.people 
    JOIN public.program_enrolments ON people.id = program_enrolments.student
    JOIN public.semesters ON program_enrolments.semester = semesters.id
GROUP BY 
    people.unswid, 
    program_enrolments.program
HAVING 
    (MAX(semesters.ending) - MIN(semesters.starting)) > 2000;

CREATE VIEW students_less_than_half_uoc AS
SELECT 
    people.unswid AS student_id, 
    program_enrolments.program AS program_id, 
    (programs.uoc - SUM(subjects.uoc)) AS remain_uoc
FROM 
    program_enrolments
JOIN 
    people ON program_enrolments.student = people.id
JOIN 
    semesters ON program_enrolments.semester = semesters.id
JOIN
    programs ON program_enrolments.program = programs.id
JOIN 
    program_degrees ON program_enrolments.program = program_degrees.program
JOIN 
    course_enrolments ON course_enrolments.student = people.id AND course_enrolments.mark >= 50
JOIN 
    courses ON course_enrolments.course = courses.id
JOIN 
    subjects ON courses.subject = subjects.id
WHERE 
    program_degrees.abbrev = 'MA' AND 
    program_enrolments.semester = courses.semester
GROUP BY 
    people.unswid, 
    program_enrolments.program,
    programs.uoc
HAVING 
    SUM(subjects.uoc) < programs.uoc / 2;


create or replace view Q10(student_id, program_id, remain_uoc)
as
SELECT 
    students_less_than_half_uoc.student_id, 
    students_less_than_half_uoc.program_id, 
    students_less_than_half_uoc.remain_uoc
FROM 
    students_less_than_half_uoc
JOIN 
    enrolled_over_2000_days 
ON 
    students_less_than_half_uoc.student_id = enrolled_over_2000_days.unswid;

 --... SQL statements, possibly using other views/functions defined by you ...

;

-- Q11
create or replace function 
	Q11(year courseyeartype, term character(2), orgunit_id integer) returns setof text
as $$
DECLARE
    student_count numeric;
    grade text;
    ratio numeric;
    grade_label text;
    min_mark_percentage numeric;
    max_mark_percentage numeric;
BEGIN
    SELECT COUNT(DISTINCT course_enrolments.student)
    INTO student_count
    FROM course_enrolments 
    JOIN courses ON course_enrolments.course = courses.id
    JOIN program_enrolments ON course_enrolments.student = program_enrolments.student AND courses.semester = program_enrolments.semester
    JOIN programs ON program_enrolments.program = programs.id
    JOIN semesters on courses.semester = semesters.id
    JOIN orgunits on programs.offeredby = orgunits.id
    WHERE semesters.year = $1 AND semesters.term = $2 AND orgunits.id = $3 AND course_enrolments.mark IS NOT NULL;

    FOR grade_label, min_mark_percentage, max_mark_percentage IN 
        (VALUES ('HD', 85, NULL), ('DN', 75, 85), ('CR', 65, 75), ('PS', 50, 65), ('FL', 0, 50))
    LOOP
        IF max_mark_percentage IS NULL THEN
            SELECT 
                grade_label,
                COUNT(*) / student_count
            INTO grade, ratio
            FROM (
                SELECT 
                    course_enrolments.student, 
                    AVG(course_enrolments.mark) as avg_mark
                FROM course_enrolments 
                JOIN courses ON course_enrolments.course = courses.id
                JOIN program_enrolments ON course_enrolments.student = program_enrolments.student AND courses.semester = program_enrolments.semester
                JOIN programs ON program_enrolments.program = programs.id
                JOIN semesters on courses.semester = semesters.id
                JOIN orgunits on programs.offeredby = orgunits.id
                WHERE semesters.year = $1 AND semesters.term = $2 AND orgunits.id = $3 AND course_enrolments.mark IS NOT NULL
                GROUP BY course_enrolments.student
                HAVING AVG(course_enrolments.mark) >= min_mark_percentage
            ) s;
        ELSE
            SELECT 
                grade_label,
                COUNT(*) / student_count
            INTO grade, ratio
            FROM (
                SELECT 
                    course_enrolments.student, 
                    AVG(course_enrolments.mark) as avg_mark
                FROM course_enrolments 
                JOIN courses ON course_enrolments.course = courses.id
                JOIN program_enrolments ON course_enrolments.student = program_enrolments.student AND courses.semester = program_enrolments.semester
                JOIN programs ON program_enrolments.program = programs.id
                JOIN semesters on courses.semester = semesters.id
                JOIN orgunits on programs.offeredby = orgunits.id
                WHERE semesters.year = $1 AND semesters.term = $2 AND orgunits.id = $3 AND course_enrolments.mark IS NOT NULL
                GROUP BY course_enrolments.student
                HAVING AVG(course_enrolments.mark) >= min_mark_percentage AND AVG(course_enrolments.mark) < max_mark_percentage
            ) s;
        END IF;

        RETURN NEXT grade || ' ' || ROUND(ratio::numeric, 4)::text;
    END LOOP;
    RETURN;
END;
$$ LANGUAGE plpgsql;





-- Q12
create or replace function 
	Q12(subject_prefix character(4)) returns setof text
AS $$
DECLARE
  _course_id integer;
  _orgs text[];
  _result text;
BEGIN
  FOR _course_id, _orgs IN 
      SELECT 
        public.courses.id AS course_id, 
        ARRAY_AGG(DISTINCT public.affiliations.orgunit ORDER BY public.affiliations.orgunit) AS orgs
      FROM 
        public.courses 
      JOIN 
        public.subjects ON public.courses.subject = public.subjects.id 
      JOIN 
        public.course_staff ON public.course_staff.course = public.courses.id 
      JOIN 
        public.affiliations ON public.course_staff.staff = public.affiliations.staff 
      WHERE 
        public.subjects.code LIKE subject_prefix || '%' 
      GROUP BY 
        public.courses.id 
      HAVING 
        COUNT(DISTINCT public.affiliations.orgunit) >= 4
  LOOP
    _result := _course_id || ' ' || array_to_string(_orgs, '/');
    RETURN NEXT _result;
  END LOOP;
END; 
$$ LANGUAGE plpgsql;









