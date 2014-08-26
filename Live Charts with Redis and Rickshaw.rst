
.. code:: python

    from IPython.core.display import Javascript
    from redis import StrictRedis
    
    from IPython.html import widgets # Widget definitions
    from IPython.display import display # Used to display widgets in the notebook
    from IPython.utils.traitlets import Unicode, Float # Used to declare attributes of our widget
    
    class ChartWidget(widgets.DOMWidget):
        _view_name = Unicode('ChartView', sync=True)
        value = Float(sync=True)
.. code:: python

    %%html
    
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.4.11/d3.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/rickshaw/1.4.6/rickshaw.js"></script>


.. raw:: html

    
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/d3/3.4.11/d3.js"></script>
    <script type="text/javascript" src="https://cdnjs.cloudflare.com/ajax/libs/rickshaw/1.4.6/rickshaw.js"></script>


.. code:: python

    %%javascript
    
    require(["widgets/js/widget"], function(WidgetManager){    
        
        var seriesData = [ 
                            { x: 0, y: 40 }, 
                            { x: 1, y: 49 }, 
                            { x: 2, y: 38 }, 
                            { x: 3, y: 30 }, 
                            { x: 4, y: 32 } ];
        var x = 5;
        var graph;
        // Define the HandsonTableView
        var ChartView = IPython.DOMWidgetView.extend({
            
            render: function(){
                graph = new Rickshaw.Graph( {
                    element: this.$el[0], 
                    width: 500, 
                    height: 200, 
                    series: [{
                        color: 'steelblue',
                        data: seriesData
                    }]
                });
    
                graph.render();
            },
            update: function() {
                var newData = this.model.get('value');
                console.log("newdata", newData);
                seriesData.push( { x: x, y: newData } );
                x = x + 1;
                graph.update();
            }
        });
        
        WidgetManager.register_widget_view('ChartView', ChartView);
    });


.. parsed-literal::

    <IPython.core.display.Javascript at 0x1106a2190>


.. code:: python

    widget = ChartWidget()
    widget

.. code:: python

    r = StrictRedis()
    p = r.pubsub(ignore_subscribe_messages=True)
    p.subscribe('test')
.. code:: python

    for message in p.listen():
        widget.value = float(message['data'])
