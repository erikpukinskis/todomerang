function new_context_id_option() {
  add_new_context(prompt("I want this to come back to me when..."));
}

function add_new_context(context_name){
  new Request.JSON({ 
    url: '/contexts', 
    method: 'post', 
    data: { name: context_name },
    onFailure: function(instance){ 
      alert('oops! something went wrong.');
    }, 
    onSuccess: function(result){ 
      add_context_to_select(result);
    } 
  }).send(); 
}

function add_context_to_select(context) {
  var el = new Element('option', {'html': context.name, 'value': context.id});
  el.inject($('context_id'), 'top');
  el.selected = true;
}

function select_tab(id) {
  $$('.pane').each(function(el) {
    el.removeClass('selected');
  });
  $$('.tab').each(function(el) {
    el.removeClass('selected');
  });
  $(id + "_pane").addClass('selected');
  $(id + "_tab").addClass('selected');
}
