Model = require '../node_modules/racer/src/Model.server'
should = require 'should'
View = require '../src/View.server'

describe 'View', ->

  ResMock = ->
    @html = ''
    return
  ResMock:: =
    getHeader: ->
    setHeader: ->
    write: write = (value) -> @html += value
    send: write
    end: write

  Model::_commit = ->
  Model::bundle = ->

  it 'test view.render with no defined views', ->
    view = new View
    res = new ResMock
    view.render res
    setTimeout ->
      res.html.should.match /^<!DOCTYPE html><meta charset=utf-8><title>.*<\/title><script>.*<\/script><script.*><\/script>$/
    , 100
        
  it 'test rendering a string literal view', ->
    view = new View
    model = new Model
    view._init model
          
    view.make 'test', """
      <style>
        body {
          margin: 
            0
        }
      </style>
      """
    # String views should have line breaks and leading whitespace removed
    view.get('test').should.eql '<style>body {margin: 0}</style>'
        
  it 'test substituting variables into text', ->
    view = new View
    model = new Model
    view._init model
          
    view.make 'test', '''
      {{connected}}{{canConnect}} {{nada}}
      <p>{{name}}
      <p>{{age}} - {{height}} - {{weight}}
      '''
    ctx =
      connected: false
      weight: '165 lbs'
      nada: null
        
    model.set 'name', 'John'
    model.set 'age', 22
    model.set 'height', '6 ft 2 in'
    model.set 'weight', '175 lbs'
        
    expected = 'falsetrue ' +
      '<p>John' +
      '<p>22 - 6 ft 2 in - 165 lbs'
        
    view.get('test', ctx).should.eql expected
        
  it 'test binding variables in text', ->
    view = new View
    model = new Model
    view._init model
        
    view.make 'test', '''
      ((connected))((canConnect)) ((nada))
      <p>((name))
      <p>((age)) - ((height)) - ((weight))
      '''
    ctx =
      connected: false
      weight: '165 lbs'
      nada: null
        
    model.set 'name', 'John'
    model.set 'age', 22
    model.set 'height', '6 ft 2 in'
    model.set 'weight', '175 lbs'
  
    view.get('test', ctx).should.eql '<!--$0-->false<!--$$0--><!--$1-->true<!--$$1--> <!--$2--><!--$$2-->' +
      '<p id=$3>John' +
      '<p><!--$4-->22<!--$$4--> - <!--$5-->6 ft 2 in<!--$$5--> - <!--$6-->165 lbs<!--$$6-->'
        
  it 'test HTML escaping', ->
    view = new View
    model = new Model
    view._init model
              
    # Attribute values are escaped regardless of placeholder type
    # Ampersands are escaped at the end of a replacement even when not
    # required, because it is sometimes needed depending on the following item
    template = '''<input value=(((html)))> ((html))x(((html)))'''
    value = '<b id="hey">&Hi! & x& </b>&'
    expected =
      '<input id=$0 value="<b id=&quot;hey&quot;>&amp;Hi! & x& </b>&amp;"> ' +
      '<!--$1-->&lt;b id="hey">&amp;Hi! & x& &lt;/b>&amp;<!--$$1-->x' +
      '<!--$2--><b id="hey">&Hi! & x& </b>&<!--$$2-->'

    view.make 'test1', template
    view.get('test1', html: value).should.eql expected

    view._idCount = 0
    model.set 'html', value
    view.get('test1').should.eql expected
              
    view.make 'test2',
      '<p a={{a}} b={{b}} c={{c}} d={{d}} e={{e}} f={{f}} g={{g}} h={{h}} i>'
    view.get('test2',
      {a: '"', b: "'", c: '<', d: '>', e: '=', f: ' ', g: '', h: null}
    ).should.eql '<p a=&quot; b="\'" c="<" d=">" e="=" f=" " g="" h="" i>'
              
  it 'test conditional blocks in text', ->
    view = new View
    model = new Model
    view._init model
        
    view.make 'literal',
      '{{#show}}Yep{{^}}Nope{{/}}{{#show}} Yes!{{/}} {{^show}}No{{/}}'
    view.make 'bound',
      '((#show))Yep((^))Nope((/))((#show)) Yes!((/)) ((^show))No((/))'
        
    literalTruthy = 'Yep Yes! '
    literalFalsey = 'Nope No'
    modelTruthy = '<!--$0-->Yep<!--$$0--><!--$1--> Yes!<!--$$1--> <!--$2--><!--$$2-->'
    modelFalsey = '<!--$0-->Nope<!--$$0--><!--$1--><!--$$1--> <!--$2-->No<!--$$2-->'
        
    view.get('literal', show: true).should.eql literalTruthy
    view.get('literal', show: 1).should.eql literalTruthy
    view.get('literal', show: 'x').should.eql literalTruthy
    view.get('literal', show: {}).should.eql literalTruthy
    view.get('literal', show: [1]).should.eql literalTruthy

    view.get('literal', show: false).should.eql literalFalsey
    view.get('literal', show: undefined).should.eql literalFalsey
    view.get('literal', show: null).should.eql literalFalsey
    view.get('literal', show: 0).should.eql literalFalsey
    view.get('literal', show: '').should.eql literalFalsey
    view.get('literal', show: []).should.eql literalFalsey
    view.get('literal').should.eql literalFalsey
        
    # No parameter assumes it is a model path that is undefined
    view._idCount = 0
    view.get('bound').should.eql modelFalsey

    view._idCount = 0
    model.set 'show', true
    view.get('bound').should.eql modelTruthy
    view._idCount = 0
    model.set 'show', 1
    view.get('bound').should.eql modelTruthy
    view._idCount = 0
    model.set 'show', 'x'
    view.get('bound').should.eql modelTruthy
    view._idCount = 0
    model.set 'show', {}
    view.get('bound').should.eql modelTruthy

    view._idCount = 0
    model.set 'show', false
    view.get('bound').should.eql modelFalsey
    view._idCount = 0
    model.set 'show', undefined
    view.get('bound').should.eql modelFalsey
    view._idCount = 0
    model.set 'show', null
    view.get('bound').should.eql modelFalsey
    view._idCount = 0
    model.set 'show', 0
    view.get('bound').should.eql modelFalsey
    view._idCount = 0
    model.set 'show', ''
    view.get('bound').should.eql modelFalsey
    view._idCount = 0
    model.set 'show', []
    view.get('bound').should.eql modelFalsey

  it 'test lists in text', ->
    view = new View
    model = new Model
    view._init model

    template = """
    <ul>
    {{#arr}}
      <li>{{name}}
    {{^}}
      <li>Nothing to see
    {{/}}
    </ul>
    """

    view.make 'test', template
    view.get('test', arr: [])
      .should.eql '<ul><li>Nothing to see</ul>'

    view.make 'test', template
    view.get('test', arr: [{name: 'stuff'}, {name: 'more'}])
      .should.eql '<ul><li>stuff<li>more</ul>'

  it 'test boolean attributes', ->
    view = new View
    model = new Model
    view._init model

    view.make 'test', '<input type=checkbox checked=((maybe))>'

    view.get('test').should.eql '<input id=$0 type=checkbox>'
    view.get('test', maybe: false).should.eql '<input id=$1 type=checkbox>'
    view.get('test', maybe: true).should.eql '<input id=$2 type=checkbox checked>'
