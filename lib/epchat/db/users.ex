defmodule Epchat.Db.Users do

  def create(nickname) do
    query = """
      INSERT INTO 'users' (id, nickname) VALUES (?, ?); 
    """
    # TODO: Get the ids length from config
    id = Epchat.Utils.generate_b62 15

    # TODO: Check that id does not already exists

    # TODO: Handle possible error
    Epchat.Db.Db.execute query, [id, nickname]

    get id
  end

  def get(id) do
    query = """
      SELECT id, nickname FROM 'users' WHERE id=?; 
    """
    # TODO: Handle possible error
    Epchat.Db.Db.execute query, [id]
  end

  def all() do
    query = """
      SELECT id, nickname FROM 'users'; 
    """
    # TODO: Handle possible error
    Epchat.Db.Db.execute query
  end

  def update(id, nickname) do
    query = """
      UPDATE 'users' SET nickname=? WHERE id=?; 
    """
    # TODO: Handle possible error
    Epchat.Db.Db.execute query, [nickname, id]
  end
end
