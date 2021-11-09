using Statistics
using DataFrames
using CSV



ctry=Dict([
("Austria", "AT"), ("Bulgaria", "BG"), ("Croatia", "HR"), ("Czech", "CZ"), ("Finland", "FI"),
("France", "FR"), ("Germany", "DE"), ("Great Britain", "UK") ,("Hungary", "HU"),("Italy", "IT"), ("Norway", "NO"),
("Poland", "PL"), ("Portugal", "PT"), ("Romania", "RO"), ("Serbia", "RS"), ("Slovakia", "SK"), ("Slovenia", "SI"),
("Spain", "ES"), ("Sweden", "SE"), ("Ukraine", "UA")])

ctry=Dict(lowercase.([keys(ctry)...]).=> [values(ctry)...])
dn=DataFrame(nctry=[keys(ctry)...],cctry=[values(ctry)...])
dn.ind=LinearIndices(1:length(dn.cctry)) #numerical index of the country

yr=2018 #baseline year




############################################################################################################
######################															############################
###############				 	LOADING DATA FROM SBS EUROSTAT					#############################
#################																##############################
############################################################################################################

function euroclean(yr)
	sbs=DataFrame(CSV.File("$(homedir())\\Desktop\\ORBIS\\eurostat\\turnover_calc\\sbs_na_ind_r2_1_Data.csv"; select=[:TIME,:GEO,:INDIC_SB,:NACE_R2,:Value]))

	#we clean the dataset a little
	df=sbs[(in(dn.cctry).(sbs.GEO)) .& (sbs.TIME.>2007),:] ; df=df[df.INDIC_SB.=="V12110",:] #V12110 is turnover
	df=DataFrame(year=df[:,:TIME],ctry=df[:,:GEO],nace=df[:,:NACE_R2],prod=df[:,:Value])
	df=df[df.year.==yr,:] ; df=df[(startswith).(df.nace,"C"),:] ;
	df.prod=replace.(df.prod, "," => "") #the data is presented with a comma
	[df.nace[i]=replace(df.nace[i], "C" => "" ) for i in eachindex(df.nace) if isequal(df.nace[i],"C")==0]

	df[:,:erev].=tryparse.(Float64,string.(df.prod)) ; df=df[:,Not("prod")]
	[df.erev[i]=df.erev[i]*1e6 for i in eachindex(df.erev) if isnothing(df.erev[i])==0] # value is in millions, so we convert them into units
	edf=copy(df[df.nace.!="C",:])

	#we separate values  according to nace4, nace3,nace2 (it includes missing values)
	#cstr indicates whether the cell only includes numbers (i.e. it's an industry category)
	function cstr(a)  return tryparse(Float64, a)!== nothing ?  false : true end
		edf[:,:nace4].="" ; edf[:,:nace3].="" ; edf[:,:nace2].=""
		[edf.nace4[i]=edf.nace[i] for i in eachindex(edf.nace) if ((length(edf.nace[i])==4) & (cstr(edf.nace[i])==0)).==1]
		[edf.nace4[i]=edf.nace[i] for i in eachindex(edf.nace) if ((length(edf.nace[i])==4) & (cstr(edf.nace[i])==0)).==1]
		[edf.nace3[i]=edf.nace[i] for i in eachindex(edf.nace) if ((length(edf.nace[i])==3) & (cstr(edf.nace[i])==0)).==1]
		[edf.nace2[i]=edf.nace[i] for i in eachindex(edf.nace) if ((length(edf.nace[i])==2) & (cstr(edf.nace[i])==0)).==1]

		edf4=edf[edf.nace4.!="",:]
		edf3=edf[edf.nace3.!="",Not(["nace4"])]
		edf2=edf[edf.nace2.!="",Not(["nace4","nace3"])]
		dff4=copy(edf4)

		[dff4.nace3[i]=SubString(dff4.nace4[i],1:3) for i in eachindex(dff4.nace4)]
		[dff4.nace2[i]=SubString(dff4.nace4[i],1:2) for i in eachindex(dff4.nace4)]

		edff3=copy(edf3[:,[:year,:ctry,:nace3,:erev]]) ; edff3=rename!(edff3, :erev => :erev33)
		edff2=copy(edf2[:,[:year,:ctry,:nace2,:erev]]) ; edff2=rename!(edff2, :erev => :erev22)
		dff4=leftjoin(dff4,edff3,on=[:year,:ctry,:nace3])
		dff4=leftjoin(dff4,edff2,on=[:year,:ctry,:nace2])
		dff4=dff4[:,Not([:nace])]
		dff4=dff4[dff4.erev.!=0.0,:]
	return dff4
end


function missi(df)
	df[:,:mis4].=0 ; [(if df.erev[i]==nothing df.mis4[i]=1 end) for i in eachindex(df.ctry)]
	df[:,:mis33].=0 ; [(if df.erev33[i]==nothing df.mis33[i]=1 end) for i in eachindex(df.ctry)]
	df[:,:mis22].=0 ; [(if df.erev22[i]==nothing df.mis22[i]=1 end) for i in eachindex(df.ctry)]
	df[:,:mis].=0 ; [(if ( (df.mis4[i]==1) & (df.mis22==1) ) df.mis[i]=1 end) for i in eachindex(df.ctry)]

	df=transform(DataFrames.groupby(df,[:year,:ctry,:nace2]), nrow => :nr2)
	df=mapcols(col -> replace(col, nothing=>missing), df)
return df
end


function missi2(df,x,y)
	df[:,:mis].=0 ; [(if df[:,Symbol("$x")][i]==y df.mis[i]=1 end) for i in eachindex(df.ctry)]
	df=transform(DataFrames.groupby(df,[:ctry,:nace2]),:mis => sum => :mis2)
	df=transform(DataFrames.groupby(df,[:ctry,:nace2]), nrow => :nr2)

	remsh(x,y)=sum(x[i]*(x[i]!=y) for i in eachindex(x) if (ismissing(x[i])==0))
	df=transform(DataFrames.groupby(df,[:ctry,:nace2]),Symbol("$x") => ( x -> 1-remsh(x,-1) ) => :remsh2)
	df=mapcols(col -> replace(col, nothing=>missing), df)

	return df
end




############################################################################################################
######################															############################
###############				revenue shares of nace4 							######
#################			 for a given nace2									#############################
#################																##############################
############################################################################################################

############################################################################################################
###############				 	1) SHARES WE CAN RECOVER at NACE 42 					#############################
############################################################################################################

###############				 	FOR NACE 2						#############################

dff4=euroclean(yr)
dff4=missi(dff4)
sort!(dff4,[:ctry,:nace4]);
