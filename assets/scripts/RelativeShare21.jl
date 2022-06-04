using DataFrames
using CSV
using Pipe

#= 	This code creates the function `create_dff2`.
	It provides revenue shares at 2-digits NACE level relative to manufacturing revenue.=#

function create_dff2(baselineyear,dn,dir_info_eurostat,dir_info_orbis)


###############################################
#	 CLEANING FUNCTION FOR SBS EUROSTAT DATA
###############################################
function euroclean(yr)
	df = @pipe DataFrame(CSV.File("$(dir_info_eurostat)\\turnover\\sbs_na_ind_r2_1_2005-2020.csv"; 
                            select=[:TIME,:GEO,:INDIC_SB,:NACE_R2,:Value])) |>
	           _[(in(dn.cctry).(_.GEO)) .& (_.TIME.>2007) .& (_.INDIC_SB.=="V12110"),:] #turnover from Eurostat's page

	#we start by minimally cleaning the dataset
	df = @pipe  DataFrame(year=df[:,:TIME],ctry=df[:,:GEO],nace=df[:,:NACE_R2],prod=df[:,:Value]) |>
				_[(_.year.==yr) .& ((startswith).(_.nace,"C")),:]  # we keep manufacturing
	df[!,:prod] = replace.(df.prod, "," => "") #the data is presented with a comma
	[df.nace[i] = replace(df.nace[i], "C" => "") for i in eachindex(df.nace) if isequal(df.nace[i],"C")==0]

	df[:,:erev] = tryparse.(Float64,string.(df.prod)) 	
	[df.erev[i]  = df.erev[i]*1e6 for i in eachindex(df.erev) if isnothing(df.erev[i])==0] # value is in millions, so we reconvert them
	df = df[:,Not("prod")]

    #=  We discard countries that have no info for that year.
        This is decided based on whether they report manuf data. =#
    df = let
            temp1         = copy(df[df.nace.=="C",:])
            temp1[!,:tag] = isnothing.(temp1.erev).==0
            temp2         = temp1[:,[:year,:ctry,:tag]]
            @pipe leftjoin(df,temp2,on=[:year,:ctry]) |>
                    _[_.tag.==true,Not(:tag)] 
         end
			
	# `manuf_rev` -> total manuf revenue
    df = @pipe  unique(df[(df.nace.=="C"),[:erev,:year,:ctry]]) |>
                rename(_, :erev => :manuf_rev) |>
                leftjoin(df[df.nace.!="C",:],_,on=[:year,:ctry])
            
	#we split values according to nace2 (it includes missing values)
	dff2 = @pipe df[length.(df.nace).==2,:] |>
                rename(_, :nace => :nace2)
    dff2[!,:erev] = replace(dff2.erev, nothing => missing)
    dff2[!,:mis] = (ismissing.(dff2.erev)) 
	return dff2
end


##################################################
# 1) WE LOAD DATA FROM EUROSTAT FOR THE BASELINE YEAR
##################################################
dff2 = euroclean(baselineyear)


##################################################
# 1a) NO MISSING VALUES
##################################################
#  `:rsh2` -> it stores the values that are final because don't have any problem in Eurostat.      
dff2[!,:rsh2] = ifelse.(dff2.mis.==0, dff2.erev ./ dff2.manuf_rev, -1.0)


#=  For countries with no missing values:
    The sum of its shares do not necessarily sum to one, due to rounding by Eurostat.     
    We correct for this. =# 
transform!(groupby(dff2,[:ctry]), :mis => (y-> any((x->x.==true), y) )=>  :ctry_with_issue)

dff2.rsh2 = let dff2 = copy(dff2)
    temp = view(dff2,dff2.ctry_with_issue.==0,:)
    transform!(groupby(temp,[:ctry]), :rsh2 => (x -> sum(x .* (x.!=-1))) => :Tnewsh)
    temp.rsh2 = temp.rsh2 ./ temp.Tnewsh
    dff2.rsh2
            end

#=  we specify the remaining share to be explained in each nace4 
    and correct for approximation errors when `nace2_with_issue.==0` =#
transform!(groupby(dff2,[:ctry]), :rsh2 => (x -> 1 - sum(x .* (x.!=-1))) => :remsh)
temp = view(dff2,(dff2.ctry_with_issue.==0),:)
    temp.remsh .= 0.0

#=  we store the nr of issues to solve, instead of `ctry_with_issue`.
    ctry_with_issue.==true` will coincide with `nrissues2.==0` =#        
transform!(groupby(dff2,[:ctry]), :mis => sum => :nrissues2)

##################################################
# 1b) FUNCTION FOR MISSING VALUES USING PREVIOUS YEARS FROM EUROSTAT
##################################################
#=  This function fixes those values where:
    * we can recover all the remaining shares 
    * there's only one missing remaining share and 
        the remaining share to be explained (`remsh2) is higher than the sum of shares coming from previous years (`Tnewsh2`)=#


#=  This function prepares the data from Eurostat to eventually correct missing values.
    It prepares a dataset `a1` with countries for which there's new info from previous years that we can use.=#
function create_data(yr,dff2)
	dfx = dropmissing(euroclean(yr))[:,Not(:mis)]
        if isempty(dfx) == 1 nothing else
    dfx[!,:rr2] = ifelse.(isequal.(dfx.erev,0), 0.0, dfx.erev ./ dfx.manuf_rev)
    dfx = dfx[:,[:ctry,:nace2,:rr2]]

    dfx = leftjoin(dff2,dfx,on=[:ctry,:nace2])

    #we identify the new info and classify the cases
    temp = view(dfx,dfx.mis.==true,:)
        temp[!,:newinfo] = (ismissing.(temp.rr2).==0) .& (temp.mis.==true)
    transform!(groupby(dfx,[:ctry]),  :newinfo => sum ∘ skipmissing => :nrinfo2) 
    dfx[!,:nrpending] = dfx.nrissues2 .- dfx.nrinfo2
    
    size(dfx)[1]==0 ? (return dff4) : (dfx = dfx[:,Not([:mis,:nrinfo2])])

    end    
    return dfx
end


function compute_eurostat2(yr,dff2)
    dfx = create_data(yr,dff2)
        if size(dfx)[1]==0 return dff2    
    else
        
    #we keep the relevant info
    temp = view(dfx,(dfx.nrpending.<=1) .& (ismissing.(dfx.newinfo).==0),:)
    transform!(groupby(temp,[:ctry]),:rr2 => sum ∘ skipmissing => :Tnewsh)

    #CASE 1: we can recover all the remaining shares
    temp1 = view(temp,temp.nrpending.==0,:)
    temp1.rsh2 = temp1.rr2 .* temp1.remsh ./ temp1.Tnewsh
    temp1.remsh .= 0.0
    temp1.nrissues2 .= 0

    
    #CASE 2: we can recover all but one remaining share, and dfx.remsh2 > dfx.Tnewsh2
    temp2 = view(temp,(temp.nrpending.==1) .& (temp.remsh .>= temp.Tnewsh),:)
    temp2.rsh2 = temp2.rr2
    [(temp2.rsh2[i] = temp2.remsh[i] - temp2.Tnewsh[i]) for i in eachindex(temp2.nace2) if (ismissing(temp2.rr2[i])==1)]
    temp2.remsh .= 0.0
    temp2.nrissues2 .= 0
        
    end
    
    dfx[!,:mis] = (dfx.rsh2.==-1)
    dfx = dfx[:,Not([:rr2,:newinfo,:nrpending])]
    return dfx
end



if baselineyear < 2019
    for year in [baselineyear + 1, baselineyear - 1, baselineyear - 2]
        dff2 = compute_eurostat2(year,dff2)
    end
else
    for year in [baselineyear - 1, baselineyear - 2]
        dff2 = compute_eurostat2(year,dff2)
    end 
end


##################################################
# 3) WE USE RELATIVE SHARES FROM ORBIS
##################################################

# we load the data (cross-section data from orbis)
odf2 = @pipe [DataFrame(CSV.File("$(dir_info_orbis)\\cross\\$(name_country)_cross_$(baselineyear).csv";
                        select=[:year,:ctry,:id,:nace4,:rev,:manuf], types=Dict(:nace4=>String7)))  
                        for name_country in dn.nctry] |>
             vcat(_...) |>
             transform(_,:nace4 => (x->SubString.(x,1,2)) => :nace2) |>
             _[10 .<= tryparse.(Int64,_.nace2) .<= 33,: ] 
    
odf2 = @pipe transform(groupby(odf2,[:ctry,:nace2]), :rev => sum => :orev2) |>
             transform(groupby(_,[:ctry]), :orev2 => sum => :orev1) |>
             unique(_[:,[:ctry,:nace2,:orev2,:orev1]])


# we use orbis dataset to compute shares
leftjoin!(dff2,odf2,on=[:ctry,:nace2])

dff2[ismissing.(dff2.orev2),:orev2] .= 0.0
dff2[!,:osh2] = ifelse.((dff2.orev2.==0), 0 , dff2.orev2 ./ dff2.orev1)

temp1 = view(dff2, dff2.mis.==true,:)
    transform!(groupby(temp1,[:ctry]), :osh2 => sum => :Tnewsh)
    temp1.rsh2 = temp1.osh2 ./ temp1.Tnewsh .* temp1.remsh
    

##################################################
# 		2b) WE SAVE THE RESULTS
##################################################
dff2 = @pipe dff2[:,[:ctry,:year,:nace2,:rsh2,:manuf_rev]] |>
			 sort(_,[:ctry,:nace2])
rename!(dff2, :rsh2 => :rsh21)


    return dff2
end
