$(function(){
  $('#invite_bubble_trigger').bubble({
    position : 'top',
    content: $("#invite_bubble_content"),
    closeSelector: '#invite_bubble_close',
    themeName:  'bubble',
    innerHtmlStyle: {
      color:'#000000',
      'background-color': 'white'
    },
    themePath: 'http://theme.instedd.org/theme/images/',
    click: true
  });
});

$(function(){
  $(".toggle").click(function () {
      $(this).closest(".collapsed").toggleClass("off");
    });
});