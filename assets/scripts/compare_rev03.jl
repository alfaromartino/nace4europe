using Statistics
using DataFrames
using CSV
using PrettyTables
using StatFiles



dir="$(homedir())\\Desktop\\ORBIS\\allcountries"
#cd("$(homedir())\\Desktop\\ORBIS\\allcountries")
include("$(homedir())\\Desktop\\ORBIS\\eurostat\\turnover_calc\\newcode02\\page\\_assets\\scripts\\func_data01.jl")



######################################################################################
####################										###############################
################ 				REVENUE FOR IND WITH MFS AND ILS		 ##############################
#################										#############################
######################################################################################

ctry=Dict([("Bulgaria", "BG"), ("Croatia", "HR"), ("Czech", "CZ"), ("Finland", "FI"),
("France", "FR"), ("Germany", "DE"), ("Hungary", "HU"),("Italy", "IT"), ("Norway", "NO"),
("Poland", "PL"), ("Portugal", "PT"), ("Romania", "RO"), ("Serbia", "RS"), ("Slovakia", "SK"), ("Slovenia", "SI"),("Great Britain","UK"),
("Spain", "ES"), ("Sweden", "SE")])

#ctry=Dict([("Austria", "AT"), ("Great Britain","UK")])




		################### WE DEFINE GROUPS OF COUNTRIES
		west=Dict([
		("Finland", "FI"),("France", "FR"), ("Germany", "DE"), ("Great Britain","UK"),
		("Italy", "IT"), ("Norway", "NO"), ("Portugal", "PT"), ("Spain", "ES"), ("Sweden", "SE")])
		west=Dict(lowercase.([keys(west)...]).=> [values(west)...])
		dnwest=DataFrame(nctry=[keys(west)...],cctry=[values(west)...])
		dnwest.ind=LinearIndices(1:length(dnwest.cctry)) #numerical index of the country

		east=Dict([("Bulgaria", "BG"), ("Croatia", "HR"), ("Czech", "CZ"),("Hungary", "HU"), ("Poland", "PL"),
		("Romania", "RO"), ("Serbia", "RS"), ("Slovakia", "SK"), ("Slovenia", "SI")])
		east=Dict(lowercase.([keys(east)...]).=> [values(east)...])
		dneast=DataFrame(nctry=[keys(east)...],cctry=[values(east)...])
		dneast.ind=LinearIndices(1:length(dneast.cctry)) #numerical index of the country

		ctry=Dict(lowercase.([keys(ctry)...]).=> [values(ctry)...])
		dn=DataFrame(nctry=[keys(ctry)...],cctry=[values(ctry)...])
		dn.ind=LinearIndices(1:length(dn.cctry)) #numerical index of the country

		######  TEST  ##############
		#ctry=Dict([("France", "FR"), ("Croatia", "HR"),("Norway", "NO")])


crit=0.05 #cutoff of revenue share that defines an IL
thresh=9 #threshold of at least 15 MFs
bb2=0 #we ensure there always are MFs
relat=0 #MFs and ILs relative to total revenue, rather than revenue with MFs
sorted="revS"
latex=0

dfs=data(ctry)
dfs=[revi(dfs[dfs.ctry.=="$(value)",:],crit,thresh,0)  for (key,value) in enumerate(dn.cctry)] # to create a vector with dfs
dfs=vcat(dfs...)

dg=unique(dfs[:,[:ctry,:Trev]])

######################################################################################
####################										###############################
################ 				DATA FROM EUROSTAT 		 ##############################
#################					REV MANUFACTURING					#############################
######################################################################################
dir2="$(homedir())\\Google Drive\\MY-PAPERS\\intangible relation\\"
sbs=DataFrame(CSV.File("$(dir2)eurostat\\data\\sbs_na_ind_r2_1_Data.csv"; select=[:TIME,:GEO,:INDIC_SB,:Value]))



#we clean a little bit the dataset
df=sbs[(in(dn.cctry).(sbs.GEO)) .& (sbs.TIME.>2007),:] ; df=df[df.INDIC_SB.=="V12110",:] # we use turnover
df=DataFrame(year=df[:,:TIME],ctry=df[:,:GEO],prod=df[:,:Value])
df=df[df.year.==2018,:]
df.prod=replace.(df.prod, "," => "") #the data is presented with a comma
df[:,:erev].=tryparse.(Float64,string.(df.prod)) ; df=df[:,Not(["prod","year"])]
[df.erev[i]=df.erev[i]*1e6 for i in eachindex(df.erev) if isnothing(df.erev[i])==0] # value is in millions, so we convert them to units

dg=leftjoin(dg,df,on=:ctry)

dg[:,:cvg].=dg.Trev ./ dg.erev .*100
sort!(dg,:cvg) ;

rename!(dn,"cctry" => "ctry")
dfg=innerjoin(dg[:,[:ctry,:cvg]],dn[:,Not("ind")],on=:ctry)
dfg.nctry.=titlecase.(dfg.nctry)
replace!(dfg.nctry,"Great Britain" => "UK")



######################################################################################
####################										###############################
################ 				TABLES AND RESULTS 		 ##############################
#################										#############################
######################################################################################



	function ctab01(dfs,dn,latex)
		df=dfg[(in(dn.cctry).(dfg.ctry)),:]

		#####to create a dataframe with results
		sort!(df,:cvg,rev=true)
		lc=["Revenue"]
		colu=[] ; [push!(colu,df.nctry[i]) for i in eachindex(df.nctry)]

		dgg=DataFrame() ; dgg[:,:("Countries")]=lc
		[dgg[:,Symbol(value)] .= Ref(0.0) for (index,value) in enumerate(colu)]
		table=round.(df[:,:cvg],digits=1)
		dgg[1,2:end]=hcat(table)

		### table in latex
		alig=[:l] ; [push!(alig,:c) for _ in 1:size(dgg)[2]-1] # for alignment
				if latex==1
				display(pretty_table(dgg, backend = Val(:latex),nosubheader=true,tf=tf_latex_booktabs,alignment=alig))
				end
		return dgg
	end



	pretty_table(ctab01(dfs,dnwest,0),header_crayon=crayon"green",tf = tf_unicode_rounded,nosubheader=true,
	highlighters = Highlighter(f      = (data, i, j) -> (j in eachindex(j)),crayon = crayon"light_blue"),
	border_crayon = crayon"black")
	pretty_table(ctab01(dfs,dneast,0),header_crayon=crayon"green",tf = tf_unicode_rounded,nosubheader=true,
	highlighters = Highlighter(f      = (data, i, j) -> (j in eachindex(j)),crayon = crayon"light_blue"),
	border_crayon = crayon"black")
