using DataFrames
using CSV
using Pipe

# The following script gathers all the results 


########################
# 			FOLDERS
########################
module Dir
	base	       	 	= "D:\\DATA"

	info_raw	       	 	= "$(base)\\information_raw"
	info_clean	       	 	= "$(base)\\information_cleaned"
	
	info_raw_eurostat	 	= "$(info_raw)\\eurostat"		
	info_clean_orbis	 	= "$(info_clean)\\ORBIS"

	codes      	 		= "$(base)\\codes\\eurostat" 
	algorithm_rev      	 	= "$(codes)\\revenue\\all_years\\algorithms"
	
	output      	 	= "$(base)\\outputs"
	output_eurostat_rev	 	= "$(output)\\eurostat\\revenue"
end

using Main.Dir


########################
# LIST OF COUNTRIES
########################

ctry=Dict([
	("Austria", "AT"), ("Bulgaria", "BG"), ("Czech", "CZ"), ("Finland", "FI"), 
	("Germany", "DE"), ("UK", "UK") ,("Hungary", "HU"),("Italy", "IT"), ("Norway", "NO"),
	("Poland", "PL"), ("Portugal", "PT"), ("Romania", "RO"), ("Serbia", "RS"), 
	("Slovakia", "SK"), ("Slovenia", "SI"), ("Spain", "ES"), ("Sweden", "SE"), ("Ukraine", "UA"),
	("Croatia", "HR"), ("France", "FR")]) 

ctry	=	Dict(lowercase.([keys(ctry)...]).=> [values(ctry)...])
dn	=	DataFrame(nctry=[keys(ctry)...],cctry=[values(ctry)...])
dn.ind  =	LinearIndices(1:length(dn.cctry)) #numerical index of the country



########################
# 	ALGORITHMS
########################

# it creates the function `dff2 = create_dff2(baselineyear,dn)`
include("$(Dir.algorithm_rev)\\RelativeShare21.jl")

# it creates the function `dff42 = create_dff4(baselineyear,dn)`
include("$(Dir.algorithm_rev)\\RelativeShare42.jl")


########################
# 	MERGING REVENUE DATA  
########################
function rev_dff(baselineyear, dn , info_raw_eurostat , info_clean_orbis)
	dff21 = create_dff2(baselineyear, dn , info_raw_eurostat , info_clean_orbis)
	dff42 = create_dff4(baselineyear, dn , info_raw_eurostat , info_clean_orbis)
	dff = leftjoin(dff42,dff21,on=[:ctry,:nace2,:year])

	dff[:,:share4] = dff.rsh42 .* dff.rsh21
	dff[:,:revenue4] = dff.share4 .* dff.manuf_rev

	rename!(dff, :rsh21 => :share2)
	dff[:,:revenue2] = dff.share2 .* dff.manuf_rev

	rename!(dff, :manuf_rev => :manuf_revenue, :ctry => :country)

	dff = dff[:,[:year,:country,:nace4,:share4,:revenue4,:nace2,:share2,:revenue2,:manuf_revenue]]
	return dff
end


dfr = let 
	 rev1(baselineyear) = rev_dff(baselineyear, dn , Dir.info_raw_eurostat , Dir.info_clean_orbis)
	 @pipe [rev1(baselineyear) for baselineyear in 2012:2019] |>
           vcat(_...) 
	  end

dff = @pipe rename(dn[:,1:2], :cctry => :country, :nctry => :country_name) |>
			leftjoin(dfr,_,on=:country) |>
			rename(_, :country => :country_code) |>
			select(_,:year,:country_name,:country_code,:)


CSV.write("$(Dir.output_eurostat_rev)\\RevenueManufacture_NACE4.csv",dff)