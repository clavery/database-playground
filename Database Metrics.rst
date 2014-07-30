
Database Metrics
----------------

Introspect a Postgresql database for important metrics.

Setup
~~~~~

.. code:: python

    from sqlalchemy import engine_from_config
    import pandas as pd
.. code:: python

    config = {
        "sqlalchemy.url" : "postgres://vagrant:vagrant@localhost/playground",
        "sqlalchemy.echo" : False
    }
    engine = engine_from_config(config)
    conn = engine.connect()
Queries
~~~~~~~

Running Queries
^^^^^^^^^^^^^^^

.. code:: python

    running_queries_sql = conn.execute("""
    SELECT
      pid,
      state,
      application_name AS source,
      age(now(), xact_start) AS duration,
      waiting,
      query,
      xact_start AS started_at
    FROM
      pg_stat_activity
    WHERE
      query <> '<insufficient privilege>'
      AND state <> 'idle'
      AND pid <> pg_backend_pid()
    ORDER BY
      query_start DESC
    """)
    running_queries = running_queries_sql.fetchall()
    df = pd.DataFrame(running_queries, columns=running_queries_sql.keys())
    df



.. raw:: html

    <div style="max-height:1000px;max-width:1500px;overflow:auto;">
    <table border="1" class="dataframe">
      <thead>
        <tr style="text-align: right;">
          <th></th>
          <th>pid</th>
          <th>state</th>
          <th>source</th>
          <th>duration</th>
          <th>waiting</th>
          <th>query</th>
          <th>started_at</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>0</th>
          <td> 15221</td>
          <td> idle in transaction</td>
          <td> </td>
          <td>14:11:11.729391</td>
          <td> False</td>
          <td> SELECT content.id AS content_id, content.name ...</td>
          <td> 2014-07-30 03:22:50.204580+00:00</td>
        </tr>
      </tbody>
    </table>
    </div>



Long Running Queries
^^^^^^^^^^^^^^^^^^^^

.. code:: python

    long_running_sql = conn.execute("""
    SELECT
      pid,
      state,
      application_name AS source,
      age(now(), xact_start) AS duration,
      waiting,
      query,
      xact_start AS started_at
    FROM
      pg_stat_activity
    WHERE
      query <> '<insufficient privilege>'
      AND state <> 'idle'
      AND pid <> pg_backend_pid()
      AND now() - query_start > interval '5 minutes'
    ORDER BY
      query_start DESC
    """)
    long_running = long_running_sql.fetchall()
    df = pd.DataFrame(long_running, columns=long_running_sql.keys())
    df



.. raw:: html

    <div style="max-height:1000px;max-width:1500px;overflow:auto;">
    <table border="1" class="dataframe">
      <thead>
        <tr style="text-align: right;">
          <th></th>
          <th>pid</th>
          <th>state</th>
          <th>source</th>
          <th>duration</th>
          <th>waiting</th>
          <th>query</th>
          <th>started_at</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>0</th>
          <td> 15221</td>
          <td> idle in transaction</td>
          <td> </td>
          <td>14:01:42.128924</td>
          <td> False</td>
          <td> SELECT content.id AS content_id, content.name ...</td>
          <td> 2014-07-30 03:22:50.204580+00:00</td>
        </tr>
      </tbody>
    </table>
    </div>



Index Usage
^^^^^^^^^^^

.. code:: python

    sql = conn.execute("""
    SELECT
      relname AS table,
      CASE idx_scan
        WHEN 0 THEN 'Insufficient data'
        ELSE (100 * idx_scan / (seq_scan + idx_scan))::text
      END percent_of_times_index_used,
      n_live_tup rows_in_table
    FROM
      pg_stat_user_tables
    ORDER BY
      n_live_tup DESC,
      relname ASC
    """)
    result = sql.fetchall()
    df = pd.DataFrame(result, columns=sql.keys())
    df



.. raw:: html

    <div style="max-height:1000px;max-width:1500px;overflow:auto;">
    <table border="1" class="dataframe">
      <thead>
        <tr style="text-align: right;">
          <th></th>
          <th>table</th>
          <th>percent_of_times_index_used</th>
          <th>rows_in_table</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>0</th>
          <td> content</td>
          <td> Insufficient data</td>
          <td> 2</td>
        </tr>
      </tbody>
    </table>
    </div>



Missing Indexs
^^^^^^^^^^^^^^

.. code:: python

    sql = conn.execute("""
    SELECT
      relname AS table,
      CASE idx_scan
        WHEN 0 THEN 'Insufficient data'
        ELSE (100 * idx_scan / (seq_scan + idx_scan))::text
      END percent_of_times_index_used,
      n_live_tup rows_in_table
    FROM
      pg_stat_user_tables
    WHERE
      idx_scan > 0
      AND (100 * idx_scan / (seq_scan + idx_scan)) < 95
      AND n_live_tup >= 10000
    ORDER BY
      n_live_tup DESC,
      relname ASC
    """)
    result = sql.fetchall()
    sql.keys()
    result
    if result:
        df = pd.DataFrame(result, columns=sql.keys())
        df
Relation / Database Size
^^^^^^^^^^^^^^^^^^^^^^^^

.. code:: python

    sql = conn.execute("""
          SELECT
              c.relname AS name,
              CASE WHEN c.relkind = 'r' THEN 'table' ELSE 'index' END AS type,
              pg_size_pretty(pg_table_size(c.oid)) AS size
            FROM
              pg_class c
            LEFT JOIN
              pg_namespace n ON (n.oid = c.relnamespace)
            WHERE
              n.nspname NOT IN ('pg_catalog', 'information_schema')
              AND n.nspname !~ '^pg_toast'
              AND c.relkind IN ('r', 'i')
            ORDER BY
              pg_table_size(c.oid) DESC,
              name ASC
    """)
    result = sql.fetchall()
    df = pd.DataFrame(result, columns=sql.keys())
    df



.. raw:: html

    <div style="max-height:1000px;max-width:1500px;overflow:auto;">
    <table border="1" class="dataframe">
      <thead>
        <tr style="text-align: right;">
          <th></th>
          <th>name</th>
          <th>type</th>
          <th>size</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>0</th>
          <td>      content</td>
          <td> table</td>
          <td> 16 kB</td>
        </tr>
        <tr>
          <th>1</th>
          <td> content_pkey</td>
          <td> index</td>
          <td> 16 kB</td>
        </tr>
      </tbody>
    </table>
    </div>



.. code:: python

    sql = conn.execute("SELECT pg_size_pretty(pg_database_size(current_database()))")
    result = sql.fetchall()
    df = pd.DataFrame(result, columns=sql.keys())
    df



.. raw:: html

    <div style="max-height:1000px;max-width:1500px;overflow:auto;">
    <table border="1" class="dataframe">
      <thead>
        <tr style="text-align: right;">
          <th></th>
          <th>pg_size_pretty</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <th>0</th>
          <td> 6596 kB</td>
        </tr>
      </tbody>
    </table>
    </div>



Kill Process
^^^^^^^^^^^^

.. code:: python

    pid = None
    
    if pid:
        sql = conn.execute("SELECT pg_cancel_backend({})".format(pid))
        result = sql.fetchall()
        print result

