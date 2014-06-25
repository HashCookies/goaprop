(function($){})(window.jQuery);

var winH = $(window).height();
var winW = $(window).width();

$(document).ready(function() {
		$('.cover').height(winH - 121).width(winW);
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
		  $grid.isotope({ 
		  	sortBy: sortValue
		  });
		  
		  $('#sort-filter li.active').removeClass('active');
		  $(this).parent().addClass('active');
		  
		  return false
		});
		
		var filters = {};
		
		$('#filters').on('click', 'a', function() {
			var $this = $(this);
			
			var $listGroup = $this.parents('.list-group');
			var filterGroup = $listGroup.attr('data-filter-group');
			
			filters[ filterGroup ] = $this.attr('data-filter');
			
			var filterValue = '';
			for (var prop in filters) {
				filterValue += filters[prop];
			}
			$grid.isotope({filter: filterValue});
			
			return false;
		});
		
		$('.list-group').each( function( i, buttonGroup ) {
		    var $buttonGroup = $( buttonGroup );
		    $buttonGroup.on( 'click', 'a', function() {
		      $buttonGroup.find('.active').removeClass('active');
		      $( this ).parent().addClass('active');
		    });
		});
				
		var $propD = $('.property-data');
		
		
		var propTop;
		
		if (winH < 760) {
			propTop = winH - 95
			$propD.css({ top: propTop });
		} else {
			propTop = 675;
			$b.addClass('scrolled');
		}
		
		
		
		$(window).scroll(function() {
			var st  = $(window).scrollTop();
			
			if (st < (760 - winH)) {
				$b.removeClass('scrolled');
			}
			
			if (st > (760 - winH)) {
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
			var title = $(this).attr('data-title');

			
			$(elem).find('.hidden-field').val(value);
			$(elem).find('.select-label').html(title).popover('hide');
			
		});
		
		// file input display image
		
		function readURL(input) {
		
		    if (input.files && input.files[0]) {
		        var reader = new FileReader();
		
		        reader.onload = function (e) {
		            $('#demo-img').attr('src', e.target.result);
		        }
		
		        reader.readAsDataURL(input.files[0]);
		    }
		}
		
		$("#featured-img-picker").change(function(){
		    readURL(this);
		});
		
		$('.demo-control').on('keyup', function() {
			var value = $(this).val();
			var id = $(this).attr('data-demo');
			$(id).html(value);
		});
		
		$('.select2').select2();
		
		$('.select2').on("change", function(e) {
			var value = e.added['text']
			var id = $(this).attr('data-demo');
			
			$(id).html(value);
		});
		
		$('.demo-control').each(function() {
			var value = $(this).val();
			var id = $(this).attr('data-demo');
			$(id).html(value);
		});
		
		$('div.select2').each(function() {
			var value = $(this).find('.select2-chosen').text();
			console.log(value);
			var id = $(this).next('select').attr('data-demo');
			
			$(id).text(value);
			
		});
		
		$('.prop-price').each(function() {
			var value = $(this).text();
			value = value.replace(/,/g, '');
			
			console.log(value);
			
			if (value.length == 7) {
				value = value.substring(0, 2);
				$(this).text(value + ' lacs');
			} 
			
			else if (value.length == 8) {
				value = value.substring(0, 1);
				$(this).text(value + ' Crore');
			} 
			
			else if (value.length == 6) {
				value = value.substring(0, 1);
				$(this).text(value + ' lacs');
			} else if (value.length < 6) {
				$(this).text("Rs. " + $(this).text());
			}
		});
});