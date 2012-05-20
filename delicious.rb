require 'httparty'

class Delicious
  # http://feeds.delicious.com/v2/{format}/tag/{tag[+tag+...+tag]}
  def get_popular(tag)
    resp = HTTParty.get('http://feeds.delicious.com/v2/json/tag/'+tag)
    
  end
  
  # http://feeds.delicious.com/v2/{format}/url/{url md5}
  # http://feeds.delicious.com/v2/json/urlinfo/{url md5}
  def get_urlposts
  end
  
  # http://feeds.delicious.com/v2/{format}/{username}
  def get_userposts
  end
end