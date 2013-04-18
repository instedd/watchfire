(function($){
  var msie_6_to_8 = $.browser.msie && 6 <= parseInt($.browser.version, 10) && parseInt($.browser.version, 10) <= 8;
  var is_chrome = navigator.userAgent.toLowerCase().indexOf('chrome') > -1;

  $.extend({
    instedd: {
      init_components: function(container) {

        if (msie_6_to_8) {
          $("button[class]:not(:empty), a[class]:not(:empty)").addClass("ie_not_empty");

          // TODO complete ie hacks for css3 that are not supported, slow with selectivzr
          // $("input[type='text']", container).addClass("ux-text");
          // $("input[type='password']", container).addClass("ux-text");
          // $("input[type='email']", container).addClass("ux-text");
          // $("textarea", container).addClass("ux-text");
          // $("input[readonly='readonly'], textarea[readonly='readonly']", container).addClass("readonly");
          // $("button[disabled]", container).addClass("disabled");
        }

        // initialize built-in components.
        if ($.fn.datepicker) {
          $(".ux-datepicker:not([readonly])", container)
            .click(function(){ $(this).datepicker("show"); })
            .datepicker();
        }

        if ($.fn.datetimepicker) {
          $(".ux-datetimepicker:not([readonly])", container)
            .click(function(){ $(this).datepicker("show"); })
            .datetimepicker();
        }


        $(".ux-wajbar", container).wajbar();

        $('input[placeholder],textarea[placeholder]', container).placeholder();

        $(".ux-nstep", container).each(function(){
          var nstep = $(this);
          var source = $("input[type='number']", nstep);
          if (source.length == 0 || !is_chrome ) {
            if (source.length == 0) {
              source = $("input[type='text']", nstep);
            }
            var min = parseInt(source.data('min'));
            min = isNaN(min) ? null : min;
            var max = parseInt(source.data('max'));
            max = isNaN(max) ? null : max;
            var kdown = $("<button>").attr('type','button').addClass('kdown').text('');
            var kup = $("<button>").attr('type','button').addClass('kup').text('');
            nstep.append(kdown).append(kup);

            if (source.attr('readonly')) {
              // is readonly
              kdown.attr('disabled', true);
              kup.attr('disabled', true);
            } else {
              var current = function(){
                var res = parseInt(source.val());
                return isNaN(res) ? 0 : res;
              };
              kdown.click(function(){
                if (min != null && min >= current()) return;
                source.val(current()-1).change();
              });
              kup.click(function(){
                if (max != null && current() >= max) return;
                source.val(current()+1).change();
              });
            }
          }
        });
      },
      init_breadcrumb: function() {
        // add in the pre-last li of the BreadCrumb a span
        var bc_items = $('.BreadCrumb li');
        if (bc_items.length >= 2) {
          var pre_last = $(bc_items[bc_items.length - 2]);
          if (msie_6_to_8) { pre_last.addClass("ie_nth-last-child_0n_2"); }
          pre_last.append($("<span>"));
        }

        // clicking on an li in BreadCrum clicks the first link in it
        $('.BreadCrumb li').click(function(event) {
          window.location = $(this).find('a')[0].href;
        });

      }
    }
  });

  $(function(){
    $.instedd.init_components($(document));

    $('.ux-collapsible > span:first-child > a, .ux-collapsible .ux-collapse-trigger').live('click', function(){
      var collapsible = $(this).closest('.ux-collapsible');
      collapsible.toggleClass('collapsed');

      if (collapsible.data('on-expanded')) {
        if (collapsible.hasClass('collapsed')) {
          collapsible.removeClass(collapsible.data('on-expanded'));
        } else {
          collapsible.addClass(collapsible.data('on-expanded'));
        }
      }

      return false;
    });

    // these are one time per page

    // pagination controls
    $(".pagination span.disabled a").live('click', function(){ return false; }); // cancel click on disabled buttons

    // position user menu
    var $user = $('#User');
    $user.click(function(event) {
      if ($user.hasClass('open')) {
        $user.removeClass('open');
      } else {
        var container = $('.container', $(this));
        var band = $('.band', container);
        if (band.length == 0) {
          container.prepend(band = $("<div>").addClass("band"));
        }
        var margin_to_center = -container.width()/2 + $(this).width()/2 - 2;
        container.css('margin-left', margin_to_center);
        var exceeded = container.offset().left + container.width() - $(window).width() + 20; // HACK 20 a bit of space

        if (exceeded > 0) {
          container.css('margin-left', margin_to_center - $(this).width()/2 - exceeded - 10); // HACK padding of container
          band.css('margin-left',  container.width()/2 + exceeded);
        } else {
          band.css('margin-left', 'auto');
          band.css('margin-right', 'auto');
        }

        band.width($(this).width() + 20); // hack padding of #User

        $user.addClass('open');
      }
      if (event.target.tagName.toLowerCase() != 'a') {
        event.stopPropagation();
      }
    });

    $('#User div.container').not('a').click(function(event) {
      if (event.target.tagName.toLowerCase() != 'a') {
        event.stopPropagation();
      }
    });

    $('html').click(function() {
      if ($user.hasClass('open')) {
        $user.removeClass('open');
      }
    });

    $.instedd.init_breadcrumb();

    // add before/after for the NavMenu
    var nav_menu = $('#NavMenu ul');
    nav_menu.prepend($('<li>')).append($('<li>'));
    var active_item = $(".active", nav_menu);
    active_item.prev().addClass('before');
    active_item.next().addClass('after');

    // homepage benefits
    window.setTimeout(function(){
      jQuery('.benefits #benefits-container').jcarousel({
        buttonNextHTML: '<div class="next"><a href="#" onclick="return false;"><span></span></a></div>',
        buttonPrevHTML: '<div class="prev"><a href="#" onclick="return false;"><span></span></a></div>'
      });
    }, 500);

    // style fixes for msie 6, 7, 8
    if (msie_6_to_8) {
      // compute iexplorer stylesheet and javascript from current theme.css and theme.js location
      var theme_js = $('script[src$="theme.js"]');
      $.getScript(theme_js.attr('src').replace('/theme.js', '/selectivizr.js'));

      var theme_css = $('link[href$="theme.css"]');
      $('head').append('<link href="' + theme_css.attr('href').replace('/theme.css', '/iexplorer.css') + '" rel="stylesheet" type="text/css" />');
    }
  });
})(jQuery);
