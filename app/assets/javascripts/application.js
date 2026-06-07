// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
// require turbolinks
//= require jquery.validate
//= require jquery.ime
//= require jquery.ime.selector
//= require jquery.ime.preferences
//= require jquery.ime.inputmethods
//= require zeroclipboard
//= require_tree .

$( document ).ready( function () {
	// Kannada ime enabled for form 
	$( '.kan-ime' ).ime();



// Jquery for home page number count incremental display
(function($) {
	"use strict";
	function count($this){
		var current = parseInt($this.html(), 10);
		current = current + 10; /* Where 50 is increment */  
		$this.html(++current);
		if(current > $this.data('count')){
			$this.html($this.data('count'));
		} else {    
			setTimeout(function(){count($this)}, 50);
		}
	}         
	$(".stat-count").each(function() {
		$(this).data('count', parseInt($(this).html(), 10));
		$(this).html('0');
		count($(this));
	});
})(jQuery);

// Wiki div hide and show


var clip = new ZeroClipboard($(".d_clip_button"))



$(function() {
	$("[name=wikiaccount]").click(function(){
		$('.toHide').hide();
		$("#blk-"+$(this).val()).show('slow');
	});
});





// Wiki styles ended


// validatin added for wiki user info form
$("#capture-wiki-id").validate({
	rules:{

		'user_name':
		{
			required: true
		}
	},
	messages:{
		'user_name':
		{
			required: "ದಯವಿಟ್ಟು ನಿಮ್ಮ ವಿಕಿ ಬಳಕೆದಾರ ಹೆಸರನ್ನು ಬೆರಳಚ್ಚು ಮಾಡಿ"
		}
	}
});

});

