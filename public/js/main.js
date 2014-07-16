(function($){})(window.jQuery);

var winH = $(window).height();
var winW = $(window).width();

$(document).ready(function() {
		$('.cover').height(winH - 100).width(winW);
		$('.info-intro').height(winH - 200).width(winW);
		var $b = $('body');
		
		$('#home-bg').anystretch();

		var strUrl = $('.info-intro').attr('data-stretch');
		$('.info-intro').anystretch(strUrl, { positionY: 'bottom' });
		
		$('.property-image-grid .anystretch').anystretch();
	
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
			
			var $listGroup = $this.parents('.filter-group');
			var filterGroup = $listGroup.attr('data-filter-group');
			
			filters[ filterGroup ] = $this.attr('data-filter');
			
			var filterValue = '';
			for (var prop in filters) {
				filterValue += filters[prop];
			}
			$grid.isotope({filter: filterValue});
			
			return false;
		});
		
		$('.filter-group').each( function( i, buttonGroup ) {
		    var $buttonGroup = $( buttonGroup );
		    $buttonGroup.on( 'click', 'a', function() {
		      $buttonGroup.find('.active').removeClass('active');
		      $( this ).parent().addClass('active');
		    });
		});
				
		var $propD = $('.property-data');
		
		
		var propTop;
		
		if (winH < 760) {
			propTop = winH - 97
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
		}).click(function() {
			return false;
		});
		
		$b.on('click', '.popover-btn', function() {
			var value = $(this).attr('data-value');
			var elem = $(this).attr('data-elem');
			var title = $(this).attr('data-title');

			
			$(elem).find('.hidden-field').val(value);
			$(elem).find('.select-label').html(title).popover('hide');
			
			return false;
			
		});

		var $delBtn = $('.delete-btn');
		var $delModal = $('.delete-modal');
		
		$delBtn.click(function() {
			var prodID = $(this).attr('data-resource-id');
			var prodName = $(this).attr('data-resource-name');
			var dataType = $(this).attr('data-type');

			$delModal.find('form').attr('action', dataType + '/destroy/' + prodID);
			$delModal.find('h4.modal-title span').text(dataType + ": " +prodName);
			
			$delModal.modal();
			
			return false;
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
		
		$('.prop-price .price').each(function() {
			var value = $(this).text();
			value = value.trim();
			var permo = value.substring(value.length - 5);
			if (permo != ' / mo'){
				permo = '';
			}

			value = value.replace(/,/g, '');
			value = value.replace(/ \/ mo/, '');
			
			console.log(value);
			//alert(value + ':' + permo + ':' + $(this).text());
			
			if (value.length == 8) {
				decValue = '.' + value.substr(1, 1);
				value = value.substring(0, 1);
				$(this).text(value + decValue + ' Crore' + permo);
			}

			else if (value.length == 7) {
				decValue = '.' + value.substr(2, 1);
				value = value.substring(0, 2);
				$(this).text(value + decValue + ' Lac' + permo);
			}
			
			else if (value.length == 6) {
				decValue = '.' + value.substr(1, 1);
				value = value.substring(0, 1);
				$(this).text(value + decValue + ' Lac' + permo);
			}

			else if (value.length < 6) {
				$(this).text($(this).text());
			}
		});
	
	setTimeout(function() {
		$b.addClass('loaded');
	}, 800)
	
	$('.gallery-images').magnificPopup({ 
		delegate: 'a',
		gallery: {
		    // options for gallery
		    enabled: true,
		    preload: [0,2], // read about this option in next Lazy-loading section
		  },
		type: 'image',
		 zoom: {
		    enabled: true, // By default it's false, so don't forget to enable it
		
		    duration: 300, // duration of the effect, in milliseconds
		    easing: 'ease-in-out', // CSS transition easing function 
		
		    // The "opener" function should return the element from which popup will be zoomed in
		    // and to which popup will be scaled down
		    // By defailt it looks for an image tag:
		    opener: function(openerElement) {
		      // openerElement is the element on which popup was initialized, in this case its <a> tag
		      // you don't need to add "opener" option if this code matches your needs, it's defailt one.
		      return openerElement.is('img') ? openerElement : openerElement.find('img');
		    }
		  }
	});
	$('.gallery-link button').click(function() {
		$('.gallery-images').magnificPopup('open');
		return false;
	});
	
	$('#contact-link a').click(function() {
		$.scrollTo('#footer', 800);
		return false;
	});
	
	$('#search-link a').click(function() {
		$('#hidden-form').slideToggle(500);
		return false;
	});
	
});