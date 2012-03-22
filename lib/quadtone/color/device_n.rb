module Color
  
  class DeviceN < Base
    
    Components = (0..7).to_a
    
    def self.component_names
      Components
    end
    
    def self.cgats_fields
      Components.map do |i|
        "DEVICE_#{i}"
      end
    end
    
    def to_gray
      Color::Gray.new(@components.find { |c| c != 0 } || 0)
    end
    
    def inspect
      "<DeviceN: %s>" % [@components.map { |c| "%3d" % (c*100) }].join(' ')
    end
    
  end
  
end