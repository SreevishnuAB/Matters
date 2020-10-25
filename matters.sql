-- DROP TRIGGER IF EXISTS update_task_status ON task_items;
-- DROP FUNCTION IF EXISTS update_status();

-- DROP TABLE IF EXISTS task_items;
-- DROP TABLE IF EXISTS tasks;
-- DROP TABLE IF EXISTS users;

-- DROP TYPE IF EXISTS tstatus;
-- DROP TYPE IF EXISTS ttype;
-- DROP TYPE IF EXISTS tpriority;


CREATE TYPE tstatus AS ENUM('Not Started', 'In Progress', 'Completed');
CREATE TYPE ttype AS ENUM('Short-term', 'Long-term');
CREATE TYPE tpriority AS ENUM('Low', 'Medium', 'High', 'Very High');

CREATE TABLE IF NOT EXISTS users(
  email VARCHAR PRIMARY KEY,
  username VARCHAR,
  password VARCHAR NOT NULL
);

CREATE TABLE IF NOT EXISTS tasks(
  id UUID PRIMARY KEY,
  title VARCHAR NOT NULL,
  task_type ttype NOT NULL,
  task_status tstatus DEFAULT 'Not Started',
  task_priority tpriority NOT NULL,
  owner_id VARCHAR REFERENCES users(email) ON DELETE CASCADE,
  date_created TIMESTAMPTZ NOT NULL,
  date_updated TIMESTAMPTZ NOT NULL
);

CREATE TABLE IF NOT EXISTS task_items(
  item_id UUID PRIMARY KEY,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE,
  item_title VARCHAR NOT NULL,
  item_priority tpriority NOT NULL,
  notes VARCHAR,
  item_status tstatus DEFAULT 'Not Started',
  date_created TIMESTAMPTZ NOT NULL,
  date_updated TIMESTAMPTZ NOT NULL
);

CREATE OR REPLACE FUNCTION update_status()
RETURNS TRIGGER
AS $$
DECLARE
  count_inprog integer := 0;
  count_completed integer := 0;
  count_notstarted integer := 0;
  new_status tstatus := 'Not Started'; 
BEGIN
  SELECT count(*) INTO count_notstarted FROM task_items
    WHERE task_id = NEW.task_id AND item_status = 'Not Started';
  SELECT count(*) INTO count_inprog FROM task_items
    WHERE task_id = NEW.task_id AND item_status = 'In Progress';
  SELECT count(*) INTO count_completed FROM task_items
    WHERE task_id = NEW.task_id AND item_status = 'Completed';
  
  IF (count_completed <> 0 AND count_inprog = 0 AND count_notstarted = 0) THEN
    new_status = 'Completed';
  ELSIF (count_inprog <> 0 OR (count_notstarted <> 0 AND count_completed <> 0)) THEN
    new_status = 'In Progress';
  END IF;

  UPDATE tasks SET task_status = new_status, date_updated = NEW.date_updated WHERE id = NEW.task_id;
  RETURN NULL;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_task_status
  AFTER DELETE OR UPDATE OF item_status
  ON task_items
  EXECUTE FUNCTION update_status();