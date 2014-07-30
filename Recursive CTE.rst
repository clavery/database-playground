
Recursive CTE w/ SQLAlchemy and Postgres
========================================

Demonstrates a recursive common table expression using SQLAlchemy ORM.
Uses a simple adjacency list model and walks up the parents, building a
path and calculating the "depth" up.

Setup
-----

.. code:: python

    from uuid import uuid4
    from datetime import datetime
    from sqlalchemy import cast, Integer, Text, engine_from_config, Column, ForeignKey
    from sqlalchemy.orm import sessionmaker, relationship, aliased
    from sqlalchemy.sql import column, label
    from sqlalchemy.sql.functions import concat
    from sqlalchemy.ext.declarative import declarative_base
    from sqlalchemy.dialects.postgresql import UUID
.. code:: python

    Model = declarative_base()
    
    
    class Content(Model):
        __tablename__ = 'content'
        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
        parent_id = Column(UUID(as_uuid=True), ForeignKey('content.id'), nullable=True)
        parent = relationship("Content", remote_side=[id])
    
        
    config = {
        "sqlalchemy.url" : "postgres://vagrant:vagrant@localhost/playground",
        "sqlalchemy.echo" : False
    }
    engine = engine_from_config(config)
    
    Model.metadata.drop_all(engine)
    Model.metadata.create_all(engine)
    
    Session = sessionmaker(bind=engine)
    session = Session()
    

Example Data
------------

.. code:: python

    root = Content()
    child1 = Content(parent=root)
    # hard code ID for example
    child2 = Content(id="f47e8c42-6f27-41a4-b28c-0eea3e26f6c5", parent=child1)
    alt_root = Content()
    
    session.add_all([root, child1, child2, alt_root])
    session.commit()
Recursive CTE
-------------

.. code:: python

    level = cast(1, Integer).label('level')
    path = cast("", Text).label('path')
    
    # Create a recursive CTE with initial row
    cte = (session.query(Content, level, cast(Content.id, Text).label('path')).
               filter(Content.id == 'f47e8c42-6f27-41a4-b28c-0eea3e26f6c5').
               cte(name="parents", recursive=True))
    
    # recurse up the parents
    parents = cte.union_all(session.query(Content, (cte.c.level + 1).label('level'), 
                                          concat(cte.c.path, '->' , Content.id)).
                            select_from(cte).
                            join(Content, Content.id == cte.c.parent_id))
    
    # Then select all from the query
    # select_entity_from ensures we are using the CTE for the actual query
    # this way the mapper knows to map to the mapped entity instead of just
    # returning a keyedtuple
    q = session.query(Content, parents.c.level, parents.c.path).select_entity_from(parents)
    contents = q.all()
    print q

.. parsed-literal::

    WITH RECURSIVE parents(id, parent_id, level, path) AS 
    (SELECT content.id AS id, content.parent_id AS parent_id, CAST(:param_1 AS INTEGER) AS level, CAST(content.id AS TEXT) AS path 
    FROM content 
    WHERE content.id = :id_1 UNION ALL SELECT content.id AS content_id, content.parent_id AS content_parent_id, parents.level + :level_1 AS level, concat(parents.path, :param_2, content.id) AS concat_1 
    FROM parents JOIN content ON content.id = parents.parent_id)
     SELECT parents.id AS parents_id, parents.parent_id AS parents_parent_id, parents.level AS parents_level, parents.path AS parents_path 
    FROM parents


.. code:: python

    for content, level, path in contents:
        print level, path

.. parsed-literal::

    1 f47e8c42-6f27-41a4-b28c-0eea3e26f6c5
    2 f47e8c42-6f27-41a4-b28c-0eea3e26f6c5->e0616cac-cfd6-484e-9dc2-8df2f56ff449
    3 f47e8c42-6f27-41a4-b28c-0eea3e26f6c5->e0616cac-cfd6-484e-9dc2-8df2f56ff449->3e7b222a-5123-43ed-abec-e7740eb2cead





.. parsed-literal::

    test


