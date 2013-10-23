class Hash
  def recursive_keys(hash = self)    
    hash.reduce(hash.keys.dup){ |keys,arr|  
      if arr[1].is_a?(Hash)             
        keys << recursive_keys(arr[1]) 
      elsif arr[0].is_a?(Hash)
        keys << recursive_keys(arr[0])            
      else
        keys << arr[0]  
      end  
    }.flatten.compact.uniq
  end
  def recursive_symbolize_keys!
    symbolize_keys!
    # symbolize each hash in .values
    values.each{|h| h.recursive_symbolize_keys! if h.is_a?(Hash) }
    # symbolize each hash inside an array in .values
    values.select{|v| v.is_a?(Array) }.flatten.each{|h| h.recursive_symbolize_keys! if h.is_a?(Hash) }
    self
  end
  def to_validation_options!
  	self.each{ |k,v|
  		if v.is_a?(Hash) 
  			v.to_validation_options! 
  		elsif v.is_a?(String)
  			s = v.scan(/\/(.*)\//).flatten
  			self[k] = Regexp.new(s.first) unless s.empty? 
  		end
  	}
  	values.select{|v| v.is_a?(Array) }.flatten.each{|h| h.to_validation_options! if h.is_a?(Hash) }
  	self
  end
end