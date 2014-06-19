(function($){})(window.jQuery);

var winH = $(window).height();
var winW = $(window).width();

$(document).ready(function() {
		$('.cover').height(winH - 70).width(winW);
		var $b = $('body');
		
		
		$('.anystretch').anystretch();
	
		$grid = $('#property-grid');
		
		$grid.isotope({
			itemSelector: '.property-item',
			getSortData: {
				price:	'[data-price] parseInt',
				area:	'[data-area] parseInt',
				date: function (itemElem) {
							var date = $(itemElem).attr('data-date');
				            return Date.parse(date);
				        }
			}
		});
		
		
		$('#sort-filter').on( 'click', 'a', function() {
		  var sortValue = $(this).parent().attr('data-sort-value');
		  $grid.isotope({ sortBy: sortValue });
		  
		  $('#sort-filter li.active').removeClass('active');
		  $(this).parent().addClass('active');
		  
		  return false
		});
		
		
		$('#location-filter a').click(function(){
		  $('#location-filter li.active').removeClass('active');
		  var selector = $(this).attr('data-filter');
		  $grid.isotope({ filter: selector });
		  $(this).parent().addClass('active');
		  return false;
		  
		  
		});
		
		
		var $propD = $('.property-data');
		var $propI = $('.property-intro');
		
		
		
		$(window).scroll(function() {
			var st  = $(window).scrollTop();
			
			
			if (st < 350) {
				$propD.css({
					top: -50 + (st / 6)	
				});
				$b.removeClass('scrolled');
			}
			
			if (st < 400) {
				$propI.css({
					top: 0 - (st / 2)
				});
			}
			
			if (st > 350) {
				$propD.css({
					top: 20
				});
				$b.addClass('scrolled');
			}

		});
		
		$('.select-label').popover({
			placement: 'bottom',
			html: true
		});
		
		$b.on('click', '.popover-btn', function() {
			var value = $(this).attr('data-value');
			var elem = '#' + $(this).attr('data-elem');
			var title = $(this).attr('data-title') + ' <span class="caret"></span>';

			
			$(elem).find('.hidden-field').val(value);
			$(elem).find('.select-label').html(title).popover('hide');
			
		});
});