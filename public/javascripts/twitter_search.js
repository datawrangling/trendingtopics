var TwitterSearch = {  
  search:function(search_term){
    this.insertAjaxHack(search_term);
  },

  insertAjaxHack:function(search_term) {    
    var url = 'http://search.twitter.com/search.json?q=' + escape(search_term) + '&callback=TwitterSearch.parseAndDisplayResults';
    
    document.writeln('<div id="twitter_search_results">');
    document.writeln(  '<span class="loading">Loading Tweets...</span>');
    document.writeln(  '<script src="'+url+'" type="text/javascript"></script>');
    document.writeln('</div>');
  },
  
  parseAndDisplayResults:function(results_json){
    this.parseResults(results_json);
    this.displayResults(results_json);
  },
    
  parseResults:function(results_json) {
    if(results_json.results.length > 0 ){
      this.last_tweet_id = results_json.results[0].id;
    }
  },
  
  displayResults:function(results_json){
    var results_container = document.getElementById('twitter_search_results');
    
    var tweetlist = '';
    
    for(var i=0; i<results_json.results.length; i++) {
      var result    = results_json.results[i];
      var text      = this.sanitizeMessageText(result.text);
      var date      = new Date(result.created_at);
      var even_odd  = 'odd';
      if(i%2 == 0) { even_odd = 'even'; }
      
      tweetlist += '<li class="result '+even_odd+'" id="result_'+result.id+'">';
      tweetlist +=   '<div class="avatar"><a target="_blank" href="http://twitter.com/'+result.from_user+'"><img src="'+result.profile_image_url+'"/></a></div>';
      tweetlist +=   '<div class="text"><a target="_blank" href="http://twitter.com/'+result.from_user+'">'+result.from_user+'</a>: <span class="msgtxt '+result.iso_language_code+'" id="msgtxt'+result.id+'">'+text+'</span></div>';
      tweetlist +=   '<div class="info">' + date.time_ago_in_words() + ' ago · <a target="_blank" class="litnv" href="http://twitter.com/home?status=@'+result.from_user+'">Reply</a> · <a target="_blank" class="lit" href="http://twitter.com/'+result.from_user+'/statuses/'+result.id+'">View Tweet</a></div>';
      tweetlist += '</li>';
    }
    
    results_container.innerHTML= '<ol id="twitter_results">' + tweetlist + '</ol>';
  },
  
  sanitizeMessageText:function(text) {
    text = text.replace('&amp;', '&');
  	
    var link_regex = new RegExp("(([a-zA-Z]+:\/\/)([a-z][a-z0-9_\..-]*[a-z]{2,6})([a-zA-Z0-9\/*-_\?&%]*))", "i");
  	text = text.replace(link_regex, '<a href="$1">$1</a>');
  	
  	var reply_regex = new RegExp("@([a-zA-Z0-9_]+)", "g");
  	text = text.replace(reply_regex, '@<a href="http://twitter.com/$1">$1</a>');
  	
    return(text);
  }
  
};

/* This function allows us to print stuff like "4 minutes ago" or "3 days ago"
   yanked from http://www.redhillconsulting.com.au/blogs/simon/archives/000426.html 
   who I suspect yanked it straight out of Rails */
Date.prototype.time_ago_in_words = function() {
    var words;
    distance_in_milliseconds = new Date() - this;
    distance_in_minutes = Math.round(  Math.abs(distance_in_milliseconds / 60000)  );

    if (distance_in_minutes == 0) {
      words = "less than a minute";
    } else if (distance_in_minutes == 1) {
      words = "1 minute";
    } else if (distance_in_minutes < 45) {
      words = distance_in_minutes + " minutes";
    } else if (distance_in_minutes < 90) {
      words = "about 1 hour";
    } else if (distance_in_minutes < 1440) {
      words = "about " + Math.round(distance_in_minutes / 60) + " hours";
    } else if (distance_in_minutes < 2160) {
      words = "about 1 day";
    } else if (distance_in_minutes < 43200) {
      words = Math.round(distance_in_minutes / 1440) + " days";
    } else if (distance_in_minutes < 86400) {
      words = "about 1 month";
    } else if (distance_in_minutes < 525600) {
      words = Math.round(distance_in_minutes / 43200) + " months";
    } else if (distance_in_minutes < 1051200) {
      words = "about 1 year";
    } else {
      words = "over " + Math.round(distance_in_minutes / 525600) + " years";
    }

    return words;
};