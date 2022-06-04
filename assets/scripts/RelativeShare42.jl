using DataFrames
using CSV
using Pipe

#= 	This code creates the function `create_dff4`
	It provides revenue shares at 4-digit NACE level relative to its 2-digits NACE level.=#

function create_dff4(baselineyear,dn,dir_info_eurostat,dir_info_orbis)


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
    
    df[:,:erev] .= tryparse.(Float64,string.(df.prod)) 	
	[df.erev[i]  = df.erev[i]*1e6 for i in eachindex(df.erev) if isnothing(df.erev[i])==0] # value is in millions, so we reconvert them
    df = df[:,Not("prod")]
	
    #=  We discard countries that have no info for that year.
        This is decided based on whether they report total revenue for manuf. =#
    df = let
            temp1         = copy(df[df.nace.=="C",:])
            temp1[!,:tag] = isnothing.(temp1.erev).==0
            temp2         = temp1[:,[:year,:ctry,:tag]]
            @pipe leftjoin(df,temp2,on=[:year,:ctry]) |>
                  _[(_.tag.==true) .& (_.nace.!="C"),Not(:tag)]                  
         end
                   
	#we separate values according to nace4 and nace2 (they include missing values)    
	dff4 = @pipe df[length.(df.nace).==4,:] |>
                 rename(_, :nace => :nace4)
    dff4[!,:nace2] = SubString.(dff4.nace4,1,2) 
    dff2 = @pipe df[length.(df.nace).==2,:] |>
                rename(_, :nace => :nace2, :erev => :erev2)
    leftjoin!(dff4,dff2,on=[:ctry,:year,:nace2])
	
    dff4[!,:erev] = replace(dff4.erev, nothing => missing)
    dff4[!,:erev2] = replace(dff4.erev2, nothing => missing)
    dff4[!,:missone] = ((ismissing.(dff4.erev).==1) .| (ismissing.(dff4.erev2).==1))
	return dff4
end


###############################################
#
#		PROCEDURE
#
###############################################


##################################################
# 1a) NO MISSING VALUES
##################################################

dff4 = euroclean(baselineyear)

#=  `:rsh42` -> it stores the values that are final because don't have any problem in Eurostat.
     we identify values to be comptued with `-1` =#
dff4[!,:rsh42] = ifelse.(dff4.missone.==false, dff4.erev ./ dff4.erev2 , -1.0)

#=  For countries-nace2 with no missing values:
    The sum of its shares do not necessarily sum to one, due to rounding by Eurostat.     
    We correct for this. =# 
transform!(groupby(dff4,[:ctry,:nace2]), :missone => (y-> any((x->x.==true), y) )=>  :nace2_with_issue)

dff4.rsh42 = let dff4 = copy(dff4)
    temp = view(dff4,dff4.nace2_with_issue.==0,:)
    transform!(groupby(temp,[:ctry,:nace2]), :rsh42 => (x -> sum(x .* (x.!=-1))) => :Tnewsh2)
    temp.rsh42 = temp.rsh42 ./ temp.Tnewsh2
    dff4.rsh42
    end

#=  we specify the remaining share to be explained in each nace4 
    and correct for approximation errors when `nace2_with_issue.==0` =#
transform!(groupby(dff4,[:ctry,:nace2]), :rsh42 => (x -> 1 - sum(x .* (x.!=-1))) => :remsh2)
temp = view(dff4,(dff4.nace2_with_issue.==0),:)
    temp.remsh2 .= 0.0



##################################################
# 1b) PARTICULAR INDUSTRIES
##################################################

function particular(dff4) 
    transform!(groupby(dff4,[:ctry,:nace2]), nrow => :nrind42)

    # We deal with cases having zeroes
        # CASE: 0s as revenue of NACE2
        temp1 = view(dff4,isequal.(dff4.erev2,0.0),:)
            temp1.remsh2 .= 0.0
            temp1.rsh42  .= 0.0 #any value that we can multiply by zero and get zero revenue
            temp1.missone = temp1.nace2_with_issue .= false

        # CASE: 0s as revenue of NACE4
        temp1 = view(dff4,isequal.(dff4.erev,0.0),:)
            temp1.rsh42 .= 0.0
            temp1.missone .= false
            
        #=  CASE: 0s as revenue of NACE4 and two industries 
            (we identify the remaining share) =#
        dff4 = let dff4 = copy(dff4)
                    aux = @pipe (isequal.(dff4.erev,0.0) .& (dff4.nrind42.==2)) |>
                                    unique(dff4[_,[:ctry,:nace2]])
                    aux[!,:tag] .= true 
                    leftjoin!(dff4,aux,on=[:ctry,:nace2])

                    temp1 = view(dff4, isequal.(dff4.tag, true) ,:)
                        temp1[ismissing.(temp1.erev),:rsh42] .= 1.0        
                        temp1.missone .= temp1.nace2_with_issue .= false
                        temp1.remsh2  .= 0.0
                    dff4[:,Not(:tag)]
                end
            
    # CASE: one 4-digit industry within NACE2
    temp1 = view(dff4, dff4.nrind42.==1 ,:)
        temp1.missone = temp1.nace2_with_issue .= false        
        temp1.rsh42  .= 1.0
        temp1.remsh2 .= 0.0

    #= CASE: These are some rare cases (for Romania), where 
             there's only one nace4 with an issue within nace2, so we can easily recover it.=#             
    transform!(groupby(dff4,[:ctry,:nace2]), :missone => sum => :nrissues4)
    temp = view(dff4,(isequal.(dff4.nrissues4,1)) .& (dff4.rsh42.==-1),:)
        temp.rsh42 = ifelse.(temp.remsh2.>0, temp.remsh2, 0.0)
    temp = view(dff4,isequal.(dff4.nrissues4,1),:)
        transform!(groupby(temp,[:ctry,:nace2]), :rsh42 => (x -> sum(x .* (x.!=-1))) => :Tnewsh2)
           temp.missone = temp.nace2_with_issue .= false
           temp.remsh2 .= 0.0
           temp.rsh42 = temp.rsh42 ./ temp.Tnewsh2

    #= we store the nr of issues to solve, instead of `nace2_with_issue` 
        `nace2_with_issue.==true` will coincide with `nrissues4.==0` =#
    transform!(groupby(dff4,[:ctry,:nace2]), :missone => sum => :nrissues4)
    return dff4[:,[:ctry,:nace4,:nace2,:missone,:rsh42,:remsh2,:nrissues4]]
end

dff4 = particular(copy(dff4))


##################################################
# 2) WE USE RELATIVE SHARES of PREVIOUS YEARS FROM EUROSTAT
##################################################
#= We now we deal with those nace4 where `dff4.nrissues4.!=0` 
    (in fact, there will be at least two issues per nace2).
   The following function prepares `dfx`, providing for nace4 from other years in Eurostat .=#

function create_data(yr,dff4)
    dfx = dropmissing(euroclean(yr))[:,Not(:missone)]
        if isempty(dfx) == 1 nothing else
    dfx[!,:rr42] = ifelse.(isequal.(dfx.erev,0), 0.0, dfx.erev ./ dfx.erev2)
    dfx = dfx[:,[:ctry,:nace4,:rr42]]

    dfx = leftjoin(dff4,dfx,on=[:ctry,:nace4])

    #we identify the new info and classify the cases
    temp = view(dfx,dfx.missone.==true,:)
        temp[!,:newinfo] = (ismissing.(temp.rr42).==0) .& (temp.missone.==true)
    transform!(groupby(dfx,[:ctry,:nace2]),	:newinfo => sum ∘ skipmissing => :nrinfo4) 
    dfx[!,:nrpending] = dfx.nrissues4 .- dfx.nrinfo4
    
    size(dfx)[1]==0 ? (return dff4) : (dfx = dfx[:,Not([:missone,:nrinfo4])])
            
    end 
    return dfx
end


        
# using the info from Eurostat of other years
function compute_eurostat(yr,dff4)
    dfx = create_data(yr,dff4) 
        if size(dfx)[1]==0 return dff4    
    else
        
    #we keep the relevant info
    temp = view(dfx,(dfx.nrpending.<2) .& (ismissing.(dfx.newinfo).==0),:)
    transform!(groupby(temp,[:ctry,:nace2]),:rr42 => sum ∘ skipmissing => :Tnewsh2)

    #CASE 1: we can recover all the remaining shares
    temp1 = view(temp,temp.nrpending.==0,:)
    temp1.rsh42 = temp1.rr42 .* temp1.remsh2 ./ temp1.Tnewsh2
    temp1.remsh2 .= 0.0
    temp1.nrissues4 .= 0

    
    #CASE 2: we can recover all but one remaining share, and dfx.remsh2 > dfx.Tnewsh2
    temp2 = view(temp,(temp.nrpending.==1) .& (temp.remsh2 .>= temp.Tnewsh2),:)
    temp2.rsh42 = temp2.rr42 
    [(temp2.rsh42[i] = temp2.remsh2[i] - temp2.Tnewsh2[i]) for i in eachindex(temp2.nace4) if (ismissing(temp2.rr42[i])==1)]
    temp2.remsh2 .= 0.0
    temp2.nrissues4 .= 0
        
    end
    
    dfx[!,:missone] = (dfx.rsh42.==-1)
    dfx = dfx[:,Not([:rr42,:newinfo,:nrpending])]
    return dfx
end



if baselineyear < 2019
    for year in [baselineyear + 1, baselineyear - 1, baselineyear - 2]
        dff4 = compute_eurostat(year,dff4)
    end
else
    for year in [baselineyear - 1, baselineyear - 2]
        dff4 = compute_eurostat(year,dff4)
    end 
end
	




##################################################
# 3) WE USE RELATIVE SHARES FROM ORBIS
##################################################

# we load the data (cross-section data from orbis)
odf4 = @pipe [DataFrame(CSV.File("$(dir_info_orbis)\\cross\\$(name_country)_cross_$(baselineyear).csv";
                        select=[:year,:ctry,:id,:nace4,:rev,:manuf], types=Dict(:nace4=>String7)))  
                        for name_country in dn.nctry] |>
             vcat(_...) |>
             transform(_,:nace4 => (x->SubString.(x,1,2)) => :nace2) |>
             _[10 .<= tryparse.(Int64,_.nace2) .<= 33,: ]


[transform!(groupby(odf4,[Symbol("nace$(i)"),:ctry]), :rev => sum => Symbol("orev$(i)")) for i in [2,4]]

odf4 = unique(odf4[:,[:ctry,:nace4,:nace2,:orev2,:orev4]])


# we use orbis dataset to compute shares
leftjoin!(dff4,odf4[:,[:ctry,:nace4,:orev4,:orev2]],on=[:ctry,:nace4])

temp1 = view(dff4, ismissing.(dff4.orev4),:)
    temp1.orev4 .= 0
    temp1.orev2 .= 0

dff4[!,:osh42] = ifelse.((dff4.orev4.==0), 0, dff4.orev4 ./ dff4.orev2)

temp1 = view(dff4, dff4.missone.==true,:)
    transform!(groupby(temp1,[:ctry,:nace2]), :osh42 => sum => :Tnewsh2)
    temp1.rsh42 = temp1.osh42 ./ temp1.Tnewsh2 .* temp1.remsh2
    


##################################################
# 4) WE SAVE THE RESULTS
##################################################
dff4[!,:year] .= baselineyear
dff4 = @pipe dff4[:,[:year,:ctry,:nace4,:nace2,:rsh42]] |>
             sort(_,[:ctry,:nace4])

    return dff4
end
