function do_processing(basefilename,pType,nEvery,project,threshold)
%   Run in OAP_Processing/img_processing directory after calling 
%   'setenv LD_LIBRARY_PATH /kingair_data/OAP_Processing/img_processing'
%   from the command line
%   
%   Example function calls:
%   do_processing('/kingair_data/tecpec19/2ds/20190305/base*.2DS','2DS',8,'TECPEC',50)
%   do_processing('/kingair_data/tecpec19/cip/20190305/20190305204555/','CIPG',8,'TECPEC',50)
%
%   Example call from the command line:
%   matlab -nodisplay -r "do_processing('dir/foo.2DS','2DS',8,'PACMICE',50)"
%
%   -Adam Majewski, 11/8/2015
%
    p = path; %current library search path
    cdir = pwd; %present processing directory
    slashpos = find(cdir == '/',1,'last');
    pdir = cdir(1:slashpos-1);

    
    
    starpos = find(basefilename == '*',1,'last');
    slashpos = find(basefilename == '/',1,'last');
    slashnum = 2;
    if strcmp(pType,'CIPG')
        slashnum = 3;
    end
    slashpos2 = find(basefilename == '/',slashnum,'last');
    slashpos2 = slashpos2(1);
    projpos = strfind(basefilename,lower(project));
    odir = [basefilename(1:projpos+length(project)+2),'oap_work/',pType,basefilename(slashpos2:slashpos)];
    ender = basefilename(slashpos+1:end);
    if isempty(dir(odir))
        system(['mkdir ',odir(1:end-1),' -p'])
    end
    files = dir(basefilename);
    if files(1).name == '.'
       files = files(3:end) 
    end
    filedir = basefilename(1:slashpos);
    if ~exist([odir,files(1).name],'file')
        for i = 1:length(files)
            system(['ln -s "',filedir,files(i).name,'" "',odir,files(i).name,'"'])
        end
    end
    
    basefilename = [odir,ender]
    logname = [odir,'log.txt']
    logid = fopen(logname,'w')
    fprintf(logid,'started: %s\r\n',datestr(now));
    
    switch pType
        case '2DC'
%pms
            if ~exist([odir,'DIMG.',ender,'.2dc.cdf'],'file')
                path(p,[pdir,'/read_binary']); %add read_binary subdirectory to search path
                fprintf(logid,'read_binary: %s\r\n',datestr(now));
                read_binary_PMS(basefilename,'1');
                
                path(p,[pdir,'/img_processing']); %add img_processing subdirectory to search path
            end
            
           
            fprintf(logid,'imgProc: %s\r\n',datestr(now));
            files = dir([odir,'DIMG.*.2dc.cdf']);
            for i=1:length(files)
                perpos = find(files(i).name == '.', 1, 'last');
                runImgProc([odir,files(i).name],pType,nEvery,project,threshold);
                if i > 1
                    mergeNetcdf([odir,files(i).name(1:perpos-1),'*.proc',files(i).name(perpos:end)]);
                end
            end
        case '2DP'
%pms
            if ~exist([odir,'DIMG.',ender,'.2dp.cdf'],'file')
                path(p,[pdir,'/read_binary']); %add read_binary subdirectory to search path
                fprintf(logid,'read_binary: %s\r\n',datestr(now));
                read_binary_PMS(basefilename,'1');
                
                path(p,[pdir,'/img_processing']); %add img_processing subdirectory to search path
            end
                
            
            fprintf(logid,'imgProc: %s\r\n',datestr(now));
            files = dir([odir,'DIMG.*.2dp.cdf']);
            for i=1:length(files)
                perpos = find(files(i).name == '.', 1, 'last');
                runImgProc([odir,files(i).name],pType,nEvery,project,threshold);
                if i > 1
                    mergeNetcdf([odir,files(i).name(1:perpos-1),'*.proc',files(i).name(perpos:end)]);
                end
            end
        case 'CIP'
            %read_binary_DMT
            
        case 'CIPG'
            %given basefilename in format /projectYY/cip/YYYYMMDD/YYYYMMDDHHMMSS/
            cipslash = find(basefilename == '/',3,'last');
            cipdir = basefilename(1:cipslash(2)); %Grabs the cip directory name
            %ciptime = basefilename(cipslash(2)+1:cipslash(2)+9); 
            ciptime = basefilename(cipslash(1)+1:cipslash(2)-1); %Grabs the date from the directory name
            path(p,[pdir,'/read_binary']); %add read_binary subdirectory to search path
            fprintf(logid,'raw_cip_to_cdf: %s\r\n',datestr(now));
            raw_cip_to_cdf(basefilename,[cipdir,'cip_',ciptime],['DIMG.',ciptime,'.cip.cdf']);
            cip_dimg = [cipdir,'cip_',ciptime,'/','DIMG.',ciptime,'.cip.cdf'];
            
            path(p,[pdir,'/img_processing']); %add img_processing subdirectory to search path
            fprintf(logid,'imgProc: %s\r\n',datestr(now));
            runImgProc(cip_dimg,pType,nEvery,project,threshold);
            
            fprintf(logid,'mergeNetcdf: %s\r\n',datestr(now));
            mergeNetcdf([cip_dimg(1:end-4),'*.proc',cip_dimg(end-3:end)]);
            
        case 'PIP'
%dmt

        case 'HVPS'
%spec

        case '2DS'
            for i=1:length(files)
                fprintf(logid,'read_binary: %s\r\n',datestr(now));
                path(p,[pdir,'/read_binary']); %add read_binary subdirectory to search path
                read_binary_SPEC([odir,files(i).name],'1');
                
                fprintf(logid,'imgProc: %s\r\n',datestr(now));
                path(p,[pdir,'/img_processing']); %add img_processing subdirectory to search path
                runImgProc([odir,'DIMG.',files(i).name,'*.cdf'],pType,nEvery,project,threshold);
                
                fprintf(logid,'mergeNetcdf H: %s\r\n',datestr(now));
                mergeNetcdf([odir,'DIMG.',files(i).name,'.H*.proc.cdf']);
                fprintf(logid,'mergeNetcdf V: %s\r\n',datestr(now));
                mergeNetcdf([odir,'DIMG.',files(i).name,'.V*.proc.cdf']);
            end
            
    end
    fprintf(logid,'finished: %s\r\n',datestr(now));
    path(p);
    fclose(logid);
end
