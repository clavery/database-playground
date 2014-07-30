
WIP Rendering SQLA Result set to JS Table
-----------------------------------------

Renders an sqlalchemy result set (ie. ORM objects) to Json and Allows
for Editing of the json via an interactive table. On change sends it
back to python code.

WIP is to encode metadata in the json suitable for referencing objects
when receiving changes. That way we can update the entities in the
actual database through the session. Basically turning Ipython and SQLA
into an interactive database interface.

Based on the notebook for interacting with pandas dataframes:
http://nbviewer.ipython.org/gist/rossant/9463955

**TODO**

-  add metadata to allowing syncing changes to backing objects
-  add metadata to change hudson cell types for date/times and numerics
   based on sqla columns
-  make read only the columns that arn't editable (maybe make primary
   key optionally read only too)
-  wrap up code into reusable widget

Getting started
~~~~~~~~~~~~~~~

There are multiple steps to make this example work (assuming you have
the latest IPython).

-  Download jquery.handsontable.full.css and
   jquery.handsontable.full.js, and put these two files in
   ~.ipython\_default.
-  In this folder, add the following line in custom.js:
   ``require(['/static/custom/jquery.handsontable.full.js']);``
-  In this folder, add the following line in custom.css:
   ``@import "/static/custom/jquery.handsontable.full.css"``

Execute this notebook.

.. code:: python

    from IPython.html import widgets # Widget definitions
    from IPython.display import display # Used to display widgets in the notebook
    from IPython.utils.traitlets import Unicode # Used to declare attributes of our widget
.. code:: python

    class HandsonTableWidget(widgets.DOMWidget):
        _view_name = Unicode('HandsonTableView', sync=True)
        value = Unicode(sync=True)
.. code:: python

    %%javascript
    var table_id = 0;
    require(["widgets/js/widget"], function(WidgetManager){    
        // Define the HandsonTableView
        var HandsonTableView = IPython.DOMWidgetView.extend({
            
            render: function(){
                // CREATION OF THE WIDGET IN THE NOTEBOOK.
                
                // Add a <div> in the widget area.
                this.$table = $('<div />')
                    .attr('id', 'table_' + (table_id++))
                    .appendTo(this.$el);
                // Create the Handsontable table.
                this.$table.handsontable({
                });
                
            },
            
            update: function() {
                // PYTHON --> JS UPDATE.
                
                // Get the model's JSON string, and parse it.
                var data = $.parseJSON(this.model.get('value'));
                // Give it to the Handsontable widget.
                this.$table.handsontable({data: data});
                
                // Don't touch this...
                return HandsonTableView.__super__.update.apply(this);
            },
            
            // Tell Backbone to listen to the change event of input controls.
            events: {"change": "handle_table_change"},
            
            handle_table_change: function(event) {
                // JS --> PYTHON UPDATE.
                
                // Get the table instance.
                var ht = this.$table.handsontable('getInstance');
                // Get the data, and serialize it in JSON.
                var json = JSON.stringify(ht.getData());
                // Update the model with the JSON string.
                this.model.set('value', json);
                
                // Don't touch this...
                this.touch();
            },
        });
        
        // Register the HandsonTableView with the widget manager.
        WidgetManager.register_widget_view('HandsonTableView', HandsonTableView);
    });


.. parsed-literal::

    <IPython.core.display.Javascript at 0x10d142b90>


.. code:: python

    import StringIO
    from uuid import UUID
    import json
    from sqlalchemy.ext.declarative import DeclarativeMeta
    def new_alchemy_encoder():
        _visited_objs = []
        class AlchemyEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj.__class__, DeclarativeMeta):
                    # don't re-visit self
                    if obj in _visited_objs:
                        return None
                    _visited_objs.append(obj)
    
                    # an SQLAlchemy class
                    fields = {}
                    for field in [x for x in dir(obj) if not x.startswith('_') and x != 'metadata']:
                        fields[field] = obj.__getattribute__(field)
                    # a json-encodable dict
                    return fields
                elif isinstance(obj.__class__, UUID):
                    return str(obj)
                else:
                    return str(obj)
                return json.JSONEncoder.default(self, obj)
        return AlchemyEncoder
        
    class SQLAResultSet(object):
        def __init__(self, result):
            self._result = result
            self._widget = HandsonTableWidget()
            self._widget.on_trait_change(self._on_data_changed, 'value')
            self._widget.on_displayed(self._on_displayed)
            
        def _on_displayed(self, e):
            # DataFrame ==> Widget (upon initialization only)
            
            self._widget.value = json.dumps(self._result, cls=new_alchemy_encoder(), check_circular=False)
            
        def _on_data_changed(self, e, val):
            # Widget ==> DataFrame (called every time the user
            # changes a value in the graphical widget)
            self._changed = json.loads(val)
            print self._changed
            
        def show(self):
            display(self._widget)
.. code:: python

    from uuid import uuid4
    from datetime import datetime
    from sqlalchemy import cast, Integer, Text, engine_from_config, Column, ForeignKey
    from sqlalchemy.orm import sessionmaker, relationship, aliased
    from sqlalchemy.sql import column, label
    from sqlalchemy.sql.functions import concat
    from sqlalchemy.ext.declarative import declarative_base
    from sqlalchemy.dialects.postgresql import UUID
    from sqlalchemy.orm import 
.. code:: python

    Model = declarative_base()
    
    
    class Content(Model):
        __tablename__ = 'content'
        id = Column(UUID(as_uuid=True), primary_key=True, default=uuid4)
        name = Column(Text)
        age = Column(Integer)
    
        
    config = {
        "sqlalchemy.url" : "postgres://vagrant:vagrant@localhost/playground",
        "sqlalchemy.echo" : False
    }
    engine = engine_from_config(config)
    
    Model.metadata.drop_all(engine)
    Model.metadata.create_all(engine)
    
    Session = sessionmaker(bind=engine)
    session = Session()
.. code:: python

    one = Content(name="Chuck", age=30)
    hannah = Content(name="Hannah", age=25)
    session.add_all([one, hannah])
    session.commit()
.. code:: python

    people = session.query(Content).all()
.. code:: python

    people



.. parsed-literal::

    [<__main__.Content at 0x111dfae90>, <__main__.Content at 0x111f9c510>]



.. code:: python

    ht = SQLAResultSet(people)
    ht.show()

.. parsed-literal::

    [{u'age': 30, u'id': u'48bca1b7-f2d8-4694-9082-d5ec6ce2a38c', u'name': u'Chuck'}, {u'age': 25, u'id': u'd07438f4-2c9f-4922-8de7-cf6c51b71673', u'name': u'Hannah'}]
    [{u'age': 30, u'id': u'48bca1b7-f2d8-4694-9082-d5ec6ce2a38c', u'name': u'Bob'}, {u'age': 25, u'id': u'd07438f4-2c9f-4922-8de7-cf6c51b71673', u'name': u'Hannah'}]
    [{u'age': 30, u'id': u'48bca1b7-f2d8-4694-9082-d5ec6ce2a38c', u'name': u'Joe'}, {u'age': 25, u'id': u'd07438f4-2c9f-4922-8de7-cf6c51b71673', u'name': u'Hannah'}]
    [{u'age': 30, u'id': u'48bca1b7-f2d8-4694-9082-d5ec6ce2a38c', u'name': u'Chuck'}, {u'age': 25, u'id': u'd07438f4-2c9f-4922-8de7-cf6c51b71673', u'name': u'Hannah'}]


