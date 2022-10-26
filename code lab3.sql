------------------------------------------------------------------------------------ЗАПОЛНЕНИЕ (ДА, СНОВА)
create table Employees
(
	full_name_employee varchar(255) not null, --фио сотрудника
	job_title varchar(255) not null, --должность
	subdivision varchar(255) not null, --подразделение
	project_code_manage integer, --код проекта, которым руководит сотрудник
    login varchar(255) not null,
    primary key (full_name_employee),
	constraint log_unique unique (login)
);

create table Projects 
(
	project_code integer not null, --код проекта
	project_name varchar(255) not null, --название проекта
	task_name varchar(255) not null, --наименование задачи
	executor_name varchar(255) not null, --фио исполнителя
	hours integer, --трудоемкость в часах
	planned_date date not null, --плановая дата выполнения
	real_date date, --реальная дата
	done boolean DEFAULT false, --отметка о принятии
	task_description text, --описание задачи
	primary key (project_code, task_name),
	constraint alternative_key unique (project_name, task_name),
   
	foreign key (executor_name) references Employees (full_name_employee)
);

insert into employees values
('Лебедева Мария Ильина', 'Менеджер', 'Отдел HR', NULL, 'lebedeva'),

('Федоров Александр Викторович', 'Тестировщик', 'Отдел тестирования', NULL, 'fedorov'),
('Минаев Михаил Богданович', 'Тестировщик', 'Отдел тестирования', NULL, 'minaev'),
('Любимова Ольга Владимировна', 'Руководитель отдела тестирования', 'Отдел тестирования', '3', 'lubimova'),

('Иванова Ульяна Леонидовна', 'Программист', 'Отдел разработки', NULL, 'ivanova'),
('Карпов Петр Дмитриевич', 'Программист', 'Отдел разработки', NULL, 'karpov'),
('Карпова Анастасия Дмитриевна', 'Руководитель отдела разработки', 'Отдел разработки', '1', 'karpova'),

('Попов Алексей Александрович', 'Дизайнер', 'Отдел дизайна', '2', 'popov');

insert into projects values
('1', 'Онлайн-игра', 'Разработать концепт 1', 'Попов Алексей Александрович', '40', '15-11-22', NULL, false, 'Task description'),
('1', 'Онлайн-игра', 'Реализовать модуль 1', 'Иванова Ульяна Леонидовна', '60', '29-11-22', NULL, false, 'Task description'),
('1', 'Онлайн-игра', 'Реализовать модуль 2', 'Иванова Ульяна Леонидовна', '80', '17-10-22', NULL, false, 'Task description'),
('1', 'Онлайн-игра', 'Реализовать модуль 3', 'Карпов Петр Дмитриевич', '100', '18-10-22', NULL, false, 'Task description'),
('1', 'Онлайн-игра', 'Протестировать', 'Минаев Михаил Богданович', '25', '15-09-22', '15-09-22', true, 'Task description'),
('1', 'Онлайн-игра', 'Руководить проектом', 'Карпова Анастасия Дмитриевна', '94', '01-01-23', NULL, false, 'Task description'),

('2', 'Корпоратив', 'Заказать еду', 'Лебедева Мария Ильина', '3', '29-12-22', '29-12-22', false, 'Task description'),
('2', 'Корпоратив', 'Организовать помещение', 'Федоров Александр Викторович', '3', '30-12-22', NULL, false, 'Task description'),
('2', 'Корпоратив', 'Руководить организацией', 'Попов Алексей Александрович', '3', '30-12-22', '31-12-22', true, 'Task description'),

('3', 'Веб-приложение', 'Верстка 1', 'Федоров Александр Викторович', '140', '03-02-24', NULL, false, 'Task description'),
('3', 'Веб-приложение', 'Верстка 2', 'Попов Алексей Александрович', '70', '15-02-24', NULL, false, 'Task description'),
('3', 'Веб-приложение', 'Тестирование, руководство', 'Любимова Ольга Владимировна', '94', '10-05-24', NULL, false, 'Task description'),
('3', 'Веб-приложение', 'Бэкенд 1', 'Иванова Ульяна Леонидовна', '80', '15-05-24', NULL, false, 'Task description'),
('3', 'Веб-приложение', 'Бэкенд 2', 'Карпова Анастасия Дмитриевна', '110', '20-12-23', NULL, false, 'Task description');



------------------------------------------------------------------------------------ТРИГГЕР (ЦЕЛОСТНОСТЬ)

CREATE function tasks_check() returns trigger
    language plpgsql as
    $$
    begin
        if new.done = old.done then
            return new;
        end if;

        if new.done = true and old.done = false then
            return new;
        elsif new.done = false and old.done = true then
            raise exception 'Can`t change done status to false';
       end if;
    end
    $$;

CREATE trigger tasks_check
    before update
    on Projects
    for each row
    execute procedure tasks_check();


------------------------------------------------------------------------------------ПОПЫТКА В ПРЕДСТАВЛЕНИЯ
--спойлер: в этой секции плохие варианты, и ничего не получилось

CREATE or replace VIEW executor_policy 
    AS SELECT project_name, task_name, executor_name, hours, planned_date, real_date, task_description
    FROM Projects
    WHERE (executor_name IN (SELECT full_name_employee
                FROM public.employees 
                WHERE login = user));



CREATE or replace VIEW executor_policy_read
    AS SELECT project_name, task_name, executor_name, hours, planned_date, real_date, task_description
    FROM Projects
    WHERE (executor_name IN (SELECT executor_name
                                FROM public.Projects
                                WHERE executor_login = CURRENT_ROLE));


--а это - просто штучки, который лень писать каждый раз

CREATE ROLE common_group;
GRANT SELECT ON TABLE executor_policy_read TO common_group;

CREATE ROLE lyubimova;
CREATE ROLE popov;
CREATE ROLE lebedeva;
CREATE ROLE ivanova;

GRANT common_group to lyubimova, popov, lebedeva, ivanova;




-- но! юзеров я создаю вот так, а не через роли (хз)

CREATE USER lubimova with encrypted password 'root';
GRANT common_group TO lubimova;

CREATE USER ivanova with encrypted password 'root';
GRANT common_group TO ivanova;

CREATE USER lebedeva with encrypted password 'root';
GRANT common_group TO lebedeva;

CREATE USER popov with encrypted password 'root';
GRANT common_group TO popov;



--моё творение
CREATE or REPLACE VIEW project_view AS
    SELECT project_code, project_name, task_name, executor_name, hours, planned_date, real_date, done, task_description
    FROM
        (SELECT project_name, task_name, executor_name, hours, planned_date, real_date, task_description
        FROM Projects
        WHERE (executor_name IN (SELECT full_name_employee
                                FROM public.employees u
                                WHERE u.login = user))) res1
        LEFT JOIN 
        (SELECT project_code, done, executor_name as employee_name, project_name as pr_name
        FROM Projects
        WHERE (project_code IN (SELECT project_code_manage
                                FROM public.employees as u
                                WHERE u.login=user  
                                    AND u.project_code_manage IS NOT NULL))) res2
ON (res1.executor_name = res2.employee_name AND res1.project_name = res2.pr_name);

--даем права на действия представлению
GRANT SELECT ON TABLE project_view TO common_group;
GRANT UPDATE (done) ON TABLE project_view TO common_group;
GRANT UPDATE (real_date) ON TABLE project_view TO common_group;


--ну и это другое представление
--просто по тз нужно, оставь этого уродца в покое
CREATE OR REPLACE VIEW Employees_view AS
    SELECT *
    FROM Employees;

GRANT SELECT ON TABLE Employees_view TO common_group;

------------------------------------------------------------------ОБНОВЛЕНИЕ


--триггер на обновление исходной таблицы
--нужно изменять только поля done и real_date
CREATE OR REPLACE FUNCTION update_projects()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
BEGIN
    --поле done может менять только руководитель проекта)))))
    IF (NEW.done != OLD.done 
        AND NEW.project_code IN (SELECT project_code_manage
                                    FROM public.employees as u
                                    WHERE u.login = current_user
                                    AND u.project_code_manage = NEW.project_code))
    THEN RETURN NEW;
    
    --поле real_date может менять только исполнитель проекта
    ELSEIF (OLD.real_date != NEW.real_date
            AND current_user IN (SELECT login
                                    FROM public.Employees u
                                    where u.login = current_user))
    THEN RETURN NEW;
    
    ELSE
		RAISE EXCEPTION 'Error: Access Denied (update_projects)';
	END IF;
END
$$;

--Триггер на обновление представления:
CREATE OR REPLACE FUNCTION update_view()
  RETURNS TRIGGER LANGUAGE PLPGSQL AS
$$
BEGIN
--меняем поле done
	IF (NEW.done != OLD.done 
        AND NEW.project_code IN (SELECT project_code_manage
                                    FROM public.employees as u
                                    WHERE u.login = current_user
                                    AND u.project_code_manage = NEW.project_code))
    THEN
        UPDATE public.project_view
        SET done = NEW.done
        WHERE (project_code, task_name) = (OLD.project_code, OLD.task_name);

--меняем поле real_date
    ELSEIF (OLD.real_date != NEW.real_date
            AND current_user IN (SELECT login
                                    FROM public.Employees u
                                    where u.login = current_user))
    THEN 
        UPDATE public.Projects
        SET real_date = NEW.real_date
        WHERE (project_code, task_name) = (OLD.project_code, OLD.task_name);

    ELSE RAISE EXCEPTION 'Error: Access Denied (update_view)';
    END IF;
	RETURN NEW;
END;
$$;




--Регистрация триггеров:
CREATE OR REPLACE trigger trigger_update_view
	INSTEAD OF UPDATE 
    ON project_view
	FOR EACH ROW 
    EXECUTE PROCEDURE update_view();

CREATE OR REPLACE trigger trigger_update_projects
	BEFORE UPDATE 
    ON Projects 
	FOR EACH ROW 
    EXECUTE PROCEDURE update_projects();

drop trigger trigger_update_projects on Projects;
drop trigger trigger_update_view on ;



--Логгирование
DROP TABLE IF EXISTS logging_table;

CREATE TABLE logging_table 
(
    id serial,
    username text not null,
    tablename text not null,
    operation text not null,
    mtime timestamp not null
);

CREATE OR REPLACE FUNCTION log_update() returns trigger as $log_update$
    BEGIN
        INSERT INTO logging_table (username, tablename, operation, mtime)
            VALUES (current_user, TG_TABLE_NAME, TG_OP, now());
        RETURN NULL;
    END;
$log_update$ LANGUAGE plpgsql;


DROP trigger IF EXISTS logging_trigger ON tasks;
CREATE trigger logging_trigger
    AFTER UPDATE ON tasks
    for each ROW EXECUTE PROCEDURE log_update();
