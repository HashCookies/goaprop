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
		
		/// PROPERTY IMAGE GRID ISOTOPE ///
	
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
		
		$grid.find('.img-block').each(function() {
			$(this).height($(this).width() * .75);
		});
		
		$('.property-item img').lazyload();
		
		$('#demo-property .img-block').height($('#demo-property .img-block').width() * 0.75);
		
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
		
		$('#filters, .sort-group').on('click', 'a', function() {
			var $this = $(this);
			
			var $listGroup = $this.parents('.filter-group');
			var filterGroup = $listGroup.attr('data-filter-group');
			
			filters[ filterGroup ] = $this.attr('data-filter');
			
			var filterValue = '';
			for (var prop in filters) {
				filterValue += filters[prop];
			}
			$grid.isotope({filter: filterValue});
			
			var parent = $this.parent().parent();
			
			if ((parent.attr('id') == "location-filter") || (parent.attr('id') == "type-filter")) {

				if (!$this.parent().hasClass('show-all')) {		
					$('#type-filter li, #location-filter li')
						.not('.show-all')
						.not($this.parent())
						.not($('#filters').find($this.attr('data-filter')))
						.slideUp(300);
					$('#reset-filters').slideDown(400, function() {
						if (parent.attr('id') == 'location-filter') {
							setTimeout(function() {
								$.scrollTo(0, 400);
							}, 200)
						}
					});
					
				}
				if ($this.parent().hasClass('show-all')) {
					
					if (parent.attr('id') == 'location-filter') {
						var activeClass = $('#type-filter .active a').attr('data-filter');
						
						if (activeClass == '') {
							parent.find('li').add('#type-filter li').slideDown(300);
						} else {
							parent.find(activeClass).slideDown(300);
						}
						
					}
					if (parent.attr('id') == 'type-filter') {
						var activeClass = $('#location-filter .active a').attr('data-filter');
						if (activeClass == '') {
							parent.find('li').add('#location-filter li').slideDown(300);
						} else {
							parent.find(activeClass).slideDown(300);
						}
					}
				}
			
			}
			
			if (parent.attr('id') == "reset-filters") {
				$('#filters li').slideDown(400, function() {
						$('#reset-filters').slideUp(400, function() {
							$grid.isotope({
								filter: "*"
							});
							$('#filters li').not('.show-all').removeClass('active');
							$('#filters li.show-all').addClass('active');
						});
						
				});
			}
			
			return false;
		});
		
		$('.filter-group').each( function( i, buttonGroup ) {
		    var $buttonGroup = $( buttonGroup );
		    $buttonGroup.on( 'click', 'a', function() {
		      $buttonGroup.find('.active').removeClass('active');
		      $( this ).parent().addClass('active');
		    });
		});
		
		setTimeout(function() {
			$grid.isotope();
		}, 5000)
		
		$(window).load(function() {
				$grid.isotope();
		
		});
		
		/// PROPERTY PAGE SCROLLING ///
				
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
			
			if ($(this).text() == "Land") {
				
				$('#search .select-state a').text("Sale").parent().find('#input-state').value("1");
			}
			
			return false;
			
		});

		var $delBtn = $('.delete-btn');
		var $delModal = $('.delete-modal');
		
		$delBtn.click(function() {
			var dataID = $(this).attr('data-resource-id');
			var dataName = $(this).attr('data-resource-name');
			var dataType = $(this).attr('data-type');

			$delModal.find('form').attr('action', '/' + dataType + '/' + dataID);
			$delModal.find('h4.modal-title span').text(dataType.substr(0, 1).toUpperCase() + dataType.substr(1) + ": " +dataName);

			$delModal.modal();
			
			return false;
		});

		//Delete Location modal
		var $delLocBtn = $('.delete-loc-btn');
		$delLocBtn.click(function() {
			var dataID = $(this).attr('data-resource-id');
			var dataName = $(this).attr('data-resource-name');
			var dataType = $(this).attr('data-type');
			var dataCount = $(this).attr('data-count');

			if (dataCount > 0) {
				$delModal.find('.has-locations').removeClass('hidden');
			}
			else {
				$delModal.find('.has-locations').addClass('hidden');
			}

			$delModal.find('form').attr('action', '/' + dataType + '/' + dataID);
			$delModal.find('h4.modal-title span').text(dataType.substr(0, 1).toUpperCase() + dataType.substr(1) + ": " +dataName);

			$delModal.modal();
			
			return false;
		});

		//Radio Buttons in Delete Locations Modal
		var $optDel = $('.optprops');
		$optDel.change(function() {
			$delForm = $delModal.find('form');
			if ($(this).val() == "delete"){
				$delModal.find('input[type=hidden][name=_method]').val('delete')
				$delForm.attr('action', $delForm.attr('action').replace('/edit',''));
			} 
			else {
				$delModal.find('input[type=hidden][name=_method]').val('get')
				$delForm.attr('action', $delForm.attr('action') + '/edit');
			}
		});

		// Email Modal
		var $emailBtn = $('.email-btn');
		var $emailModal = $('.email-modal');
		
		$emailBtn.click(function() {
			var propID = $(this).attr('data-property-id');
			$('#propID').val(propID);
			
			$emailModal.modal();
			
			return false;
		});

		//Phone/Email Validation
		var form = $('#prop-inquiry');
		var phone = $('#phone');
		var email = $('#eadd');
		
		form.submit(function() {
			if (validateForm()) {
				return true;
			} else {
				return false;
			}
		});

		function validateForm() {

			var retval = false;

			var phoneval = phone.val();
	        var emailval = email.val();
        	//validation for empty phone and email
	        if (phoneval == '') {
	        	validator('Phone cannot be empty!', 'p');
	        } else {
	        	retval = validator('', 'p');
	        }
	        if (emailval == '') {
	        	retval = validator('Email cannot be empty!', 'e');
			} else {
	        	validator('', 'e');
	        }

	        if (!retval) {
	        	return false;
	        }

			//validation for proper phone & email formats
	        var phonefilter = /^\+?\d{7,12}$/;
	        var emailfilter = /^[-a-z0-9~!$%^&*_=+}{\'?]+(\.[-a-z0-9~!$%^&*_=+}{\'?]+)*@([a-z0-9_][-a-z0-9_]*(\.[-a-z0-9_]+)*\.(aero|arpa|biz|com|coop|edu|gov|info|int|mil|museum|name|net|org|pro|travel|mobi|[a-z][a-z])|([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}))(:[0-9]{1,5})?$/i;

	        if (phonefilter.test(phoneval)) {
	        	retval = validator('', 'p');
			} else {
				retval = validator('Invalid Phone Number!', 'p');
			}

			if (emailfilter.test(emailval)) {
				validator('', 'e');
			} else {
				retval = validator('Invalid Email Address!', 'e');
			}

			return retval;
	    }

	    function validator(text, type) {
	    	item = (type == "p") ? phone : email;
	    	itemgrp = (type == "p") ? $('#phonegrp') : $('#emailgrp');
	    	itemInfo = (type == "p") ? $('#phoneInfo') : $('#emailInfo');

	    	if (text == "") {
	    		item.removeClass('has-error');
				itemgrp.removeClass('has-error');
				itemInfo.removeClass('has-error');
				itemInfo.text('');
				return true;
	    	} else {
	    		itemInfo.text(text);
				itemInfo.addClass('has-error');
				itemgrp.addClass('has-error');
				item.addClass('has-error');
				item.focus();
				return false;
	    	}
	    }
		
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


		$('.select2').each(function() {
			var val = $(this).attr('data-selected');
			$(this).select2();
			
			$(this).select2("val", val);

		});
		
		$('.select2').on("change", function(e) {
			var value = e.added['text']
			var id = $(this).attr('data-demo');
			
			$(id).html(value);
		});
		
		
		
		$('.demo-control').each(function() {
			var value = $(this).val();
			var id = $(this).attr('data-demo');
			if (id != '#demo-price'){ //stop the script from removing ' / mo' from price
				$(id).html(value); //if id demo-price dont change value in demo block.
			}
		});
		
		$('div.select2').each(function() {
			var value = $(this).find('.select2-chosen').text();
			
			var id = $(this).next('select').attr('data-demo');
			
			$(id).text(value);
			
		});

		//function to change the demo price state(rent or sale)
		$('#state_id').on("change", function(e) {
			var state = ($(this).find('option:selected').text()).toLowerCase(); //Find Sale or Rent
			var value = ($('#demo-price').text()).replace(/ \/ mo/, ''); //Clean the text of ' / mo'

			if (state == 'rent') {
				value += ' / mo'; // if rent then add ' / mo' to value
			}

			$('#demo-price').text(value);
		});

		//captures change, blur & input event on Area textbox (edit and new)
		$('#area').on('change blur input', function() {
			var value = $(this).val();
			var id = $(this).attr('data-demo');
			$(id).html(value);
		});
		
		//captures keyup, change, blur & input event on price textbox in (edit and new)
		$('#price').on('keyup change blur input', function() {
			var value = $(this).val();
			var id = $(this).attr('data-demo');
			value = value.trim();

			var state = ($('#state_id :selected').text()).toLowerCase(); //Find Sale or Rent
			
			permo = (state == 'sale') ? '' : ' / mo'; //if rent then add ' / mo'

			value = value.replace(/,/g, '');
			value = value.replace(/ \/ mo/, ''); //Clean the text of ' / mo'
			
			if (value.length == 8 || value.length == 9) { // if value in Crore/Ten Crore
				value = value.substr(0 , value.length - 6); // Strips the value into the required digits
				value = (value.slice(value.length - 1) != '0') ? [value.slice(0, value.length - 1), '.', value.slice(value.length - 1)].join('') : value.slice(0, value.length - 1);
				// adds decimal values and point at the position depending on value length if decimal value != '0'
				$(id).text(value + ' Crore' + permo);// Sets new demo price
			}

			else if (value.length == 6 || value.length == 7) { // if value in Lac/Ten Lac
				value = value.substr(0 , value.length - 4); // Strips the value into the required digits
				value = (value.slice(value.length - 1) != '0') ? [value.slice(0, value.length - 1), '.', value.slice(value.length - 1)].join('') : value.slice(0, value.length - 1);
				// adds decimal values and point at the position depending on value length if decimal value != '0'
				$(id).text(value + ' Lac' + permo); // Sets new demo price
			}

			else if (value.length <= 5) { // if value less than lac
				value = (value.length > 3) ? [value.slice(0, value.length - 3), ',', value.slice(value.length - 3)].join('') : value;
				//adds a comma after last 3 digits except if value length less than 3
				$(id).text(value + permo);
			}
		});

		$('.prop-price .price').each(function() {
			var value = $(this).text();
			value = value.trim();

			var permo = value.substring(value.length - 5); // get the last 5 characters of the string
			if (permo != ' / mo'){
				permo = ''; // clear the value of permo if it doesnt contain ' / mo'
			}
			
			value = value.replace(/,/g, ''); // strip all the ',' from value
			value = value.replace(/ \/ mo/, ''); // strip ' / mo' from value if it exists
			
			if (value.length == 8) {
				decValue = (value.substr(1, 1) != '0') ? '.' + value.substr(1, 1) : ''; //add decimal point and values if its non-zero
				value = value.substring(0, 1);
				$(this).text(value + decValue + ' Crore' + permo);
			}

			else if (value.length == 7) {
				decValue = (value.substr(2, 1) != '0') ? '.' + value.substr(2, 1) : ''; //add decimal point and values if its non-zero
				value = value.substring(0, 2);
				$(this).text(value + decValue + ' Lac' + permo);
			}
			
			else if (value.length == 6) {
				decValue = (value.substr(1, 1) != '0') ? '.' + value.substr(1, 1) : ''; //add decimal point and values if its non-zero
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
	
	$('#slide-wrap').magnificPopup({ 
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
	$('.gallery-link button, #main-img a').click(function() {
		$('#slide-wrap').magnificPopup('open');
		return false;
	});
	
	$('#contact-link a').click(function() {
		$.scrollTo('#footer', 800);
		return false;
	});
	
	if (!$b.hasClass('home')) {
		$('#search-link a').click(function() {
			$('#hidden-form').slideToggle(500);
			return false;
		});
	}
	
	$('.info-intro .inner').css({
		left: (winW - $('.info-intro .inner').width()) / 2
	});
	
	
	///// UNIT SWITCHING FUNCTION ////
	

	$.cookie.defaults = { path: '/' };
	$b.addClass($.cookie('mode'));
	
	$('#switch-unit').click(function() {
		if ($('#switch-unit').hasClass('imperial')) {
			$.cookie('mode', 'imperial');
			$('.unit-area').each(function() {
				var val = $(this).text() * 10.76;
				val = val.toFixed(0);
				$(this).text(val);
			});
			$('.unit-label').each(function() {
				$(this).text("Sq Ft");
			});
			$('#switch-unit .unit-label').text("Show in Sq Mt");
			$('#switch-unit').removeClass('imperial').addClass('metric');
		} else if ($('#switch-unit').hasClass('metric')) {
			$.cookie('mode', 'metric');
			$('.unit-area').each(function() {
				var val = $(this).text() / 10.76;
				val = val.toFixed(0);
				$(this).text(val);
			});
			$('.unit-label').each(function() {
				$(this).text("Sq Mt");
			});
			$('#switch-unit .unit-label').text("Show in Sq Ft");
			$('#switch-unit').removeClass('metric').addClass('imperial');
		}
		return false;
	});
	
	if ($b.hasClass('imperial')) { // if Body has class of Imperial, meaning show Sq Ft instead of Mts.
		$('.unit-area').each(function() {
			var val = $(this).text() * 10.76;
			val = val.toFixed(0);
			$(this).text(val);
		});
		$('.unit-label').each(function() {
			$(this).text("Sq Ft");
		});
		$('#switch-unit .unit-label').text("Show in Sq Mts");
		$('#switch-unit').removeClass('imperial').addClass('metric');
	}
	
	
	//// 
	
	var filterHeight = $('#filters').height();
	
	
	
	var $editGallery = $('.edit-gallery');

	$editGallery.shapeshift(); //edit page - order images

	$editGallery.on("ss-arranged", function(e) {
		$editGallery.children().each(function() {
			$(this).find('.ord_' + $(this).attr('id')).val($(this).index()); //set the current index value in the hidden field 
		});
	});
	
	$('.edit-gallery .remove-item').click(function() {
		$this = $(this);
		$this.parent().find('input').val('1');
		$this.parent().parent().fadeOut(400, function() {
			$('.edit-gallery').shapeshift();
		});
		
		return false;
	});
	
	$prioritySelect = $('#priority-select');
	
	$prioritySelect.find('.dropdown-menu span').click(function() {
		var $this = $(this);
		var value = $this.attr('data-value');
		$prioritySelect.find('.selected').removeClass('selected');	
		$this.parent().addClass('selected');
		$prioritySelect.find('input').val(value);
		$prioritySelect.find('.priority-tag').text($this.attr('data-tag'));
		
	});
	
	$('#property_status').on("change", function(e) {
		var value = 0;
		if 		(e.val == '1') {
			value = 6;
		}
		else if (e.val == '2') {
			value = 4;
		} 
		else if (e.val == "3") {
			value = 2;
		}
		
		$prioritySelect.find('input').val(value);
		var $this = $prioritySelect.find('.dropdown-menu li').eq(value).find('span');
		console.log($this);
		$prioritySelect.find('.selected').removeClass('selected');	
		$this.parent().addClass('selected');
		$prioritySelect.find('.priority-tag').text($this.attr('data-tag'));
	});
	
	var $prioritySelected = parseInt($prioritySelect.find('.dropdown-menu').attr('data-selected'));
	$prioritySelect.find('.dropdown-menu li').eq($prioritySelected).prev().addClass('selected');
	
	$('.btn-checkbox').click(function() {
		var $this = $(this);
		
		if ($this.hasClass('btn-active')) {
			$this.removeClass('btn-active').addClass('btn-disabled');
			$this.prev().val('false');
			$this.find('.glyphicon').removeClass('glyphicon-ok');
		} else {
			$this.find('.glyphicon').addClass('glyphicon-ok');
			$this.removeClass('btn-disabled').addClass('btn-active');
			$this.prev().val('true');
		}
		
		return false;
	});
	
	$('.disabled').click(function() {
		return false;
	});
	
});	