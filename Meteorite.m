classdef Meteorite
    %METEORITE objects are used to store meteor event data.
    %   Detailed explanation goes here.
    
    properties(Constant = true)
        
        
    end
    
    properties
        Latitude;
        Longitude;
        mass_grams;
        source;
        Notes;
                
    end
    
    methods
        function obj = untitled2(inputArg1,inputArg2)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end
    end
end

