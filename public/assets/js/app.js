$(function(){
  $('#tableSearch').on('input',function(){const q=$(this).val().toLowerCase();$('.searchable-table tbody tr').each(function(){$(this).toggle($(this).text().toLowerCase().indexOf(q)!==-1);});});
  $('#statusFilter').on('change',function(){const v=$(this).val();$('.searchable-table tbody tr').each(function(){$(this).toggle(!v || $(this).data('status')===v);});});
  $('.calendar-day').on('click',function(){$('.calendar-day').removeClass('active');$(this).addClass('active');});
  if(window.parent!==window){window.parent.postMessage({type:'kitchenflow:ready',version:'1.0.0'},'*');}
});
