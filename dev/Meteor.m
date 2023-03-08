classdef Meteor
    %METEOR objects are used to store meteor event data.
    %   Detailed explanation goes here.
    
    properties(Constant = true)
        
        
    end
    
    properties
        simindex;
        NearestTown;
        State;
        Country;
        ImportUTC;
        timezone;
        ImportLocalTime;
        nom_mass;
        nom_speed;
        nom_energy;
        nom_bearing;
        nom_angle;
        ReferenceDescription;
        nom_lat;
        nom_long;
        ref_elevation;
        geometric_elevation;
        darkflight_elevation;
        material_sim;
        material_class;
        density;
        startaltitude;
        fragaltitude;
        error_speed;
        error_bearing;
        error_angle;
        error_lat;
        error_long;
        error_elevation;
        weather_minsigma;
        weather_maxsigma;
        find_strewnarea;
        find_count;
        find_masstotal_kg;
        find_mainmass_g;
        find_medianmass_g;
        find_avgmass_g;
        find_density;
        material_CRE_Age;
        source_general;
        source_class;
        source_density;
        source_CRE_age;
        source_energy;
        source_trajectory_1;
        source_trajectory_2;
        source_trajectory_3;
        source_trajectory_4;
                
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

