<!-- =============================
     ABOUT
    ============================== -->
\begin{section}{title="Contents", name="content"}

(1) [Steps to be Taken](#sec1) \\
(2) [Eurostat](#sec2) \\  
(3) [To GitHub](#sec3) \\  \\ \\
The code has been written in \figure{path="/assets/logo_julia.png", width="10%", style="border-radius:5px;"}
\end{section}

<!-- ==============================
     GETTING STARTED
     ============================== -->
\begin{section}{title="Steps to be Taken"}\label{sec1}





```julia-repl
julia> using Statistics
julia> using DataFrames
julia> using CSV
```
\\

\end{section}


<!-- ==============================
     SPECIAL COMMANDS
     ============================== -->
\begin{section}{title="Eurostat"}\label{sec2}

\end{section}


<!-- =============================
     SHOWING CODE
    ============================== -->

\begin{section}{title="Showing Code"}


```julia
ctry=Dict([
("Austria", "AT"), ("Bulgaria", "BG"), ("Croatia", "HR"), ("Czech", "CZ"), ("Finland", "FI"),
("France", "FR"), ("Germany", "DE"), ("Great Britain", "UK") ,("Hungary", "HU"),("Italy", "IT"), ("Norway", "NO"),
("Poland", "PL"), ("Portugal", "PT"), ("Romania", "RO"), ("Serbia", "RS"), ("Slovakia", "SK"), ("Slovenia", "SI"),
("Spain", "ES"), ("Sweden", "SE"), ("Ukraine", "UA")])

ctry=Dict(lowercase.([keys(ctry)...]).=> [values(ctry)...])
dn=DataFrame(nctry=[keys(ctry)...],cctry=[values(ctry)...])
dn.ind=LinearIndices(1:length(dn.cctry)) #numerical index of the country

yr=2018; #baseline year

```


```julia
function euroclean(yr)
	#sbs=DataFrame(CSV.File("sbs_na_ind_r2_1_Data.csv"; select=[:TIME,:GEO,:INDIC_SB,:NACE_R2,:Value]))
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
```

```julia
dff4=euroclean(yr)  
dff4=missi(dff4)  
sort!(dff4,[:ctry,:nace4])
###############				 	no problem with eurostat at sh42						#############################
	dff4[:,:rsh42].=-2.0
	[((dff4.nr2[i]==1) && (dff4.rsh42[i]=1)) for i in eachindex(dff4.erev)] #only one missing value, so share within nace3 must be one
	allowmissing!(dff4)
	[(( dff4.nr2[i]!=1 ) && (dff4.rsh42[i]=dff4.erev[i]/dff4.erev22[i])) for i in eachindex(dff4.erev)]
	[( (ismissing(dff4.rsh42[i])==1) && (dff4.rsh42[i]=-1) ) for i in eachindex(dff4.erev)]
	dff4=missi2(dff4,"rsh42",-1)





###############				 	PARTITION OF THE SAMPLE						#############################
dg0=dff4[(dff4.mis2.==0),:]  #ALREADY SOLVED
	#we correct for nace42 not summing one (just in case there are problems with the decimals)
	dg0=transform(DataFrames.groupby(dg0,[:ctry,:nace2]),:rsh42 => sum => :Tnewsh2)
	dg0.rsh42.=dg0.rsh42 ./dg0.Tnewsh2


dg1=dff4[(dff4.mis2.!=0),:] # SOME PROBLEM, WE'LL PARTITION THIS IN TURN



###########################################################################################################
############################################################################################################
###############				 	2) WE USE RELATIVE SHARES FROM PREVIOUS YEARS					#############################
############################################################################################################
#########################################################################################################



#we try to recover first some of the nace42 (not using nace43)
	function solveprob1(yr,dg1)
		dg2=copy(unique(dg1[:,[:ctry,:nace4,:rsh42,:mis2]])) #they have some type  of missing value
		dga=copy(unique(dg1[dg1.mis.!=0,[:ctry,:nace4,:remsh2,:rsh42,:mis2]])) #they have some type  of missing value
		dga=rename!(dga,:mis2=>:mid2)

		a1=missi(euroclean(yr)) ; a1=dropmissing(a1)
		a1=leftjoin(dga,a1,on=[:ctry,:nace4]) ; a1=a1[:,Not([:year,:nace3,:erev33])] ; [a1.nace2[i]=SubString(a1.nace4[i],1:2) for i in eachindex(a1.nace4)]
		a1[:,:rr2].=a1.erev ./ a1.erev22


		if isempty(a1)==1
			display("empty set")
		else
		a1[:,:chek].=ismissing.(a1.rr2)
		a1=transform(DataFrames.groupby(a1,[:ctry,:nace2]),:chek => (x -> sum(skipmissing(x))) => :todrope,nrow => :todropo)
		a1=a1[(a1.todrope.!=a1.todropo),:]
		if size(a1)[1].==0
			display("no additional values") ;		return dg1
			else

			a1=a1[:,Not([:chek,:todrope,:todropo])]

			a1=transform(DataFrames.groupby(a1,[:ctry,:nace2]),
			:rr2 => (x -> sum(skipmissing(x))) => :Tnewsh2,
			:rr2 => (x -> sum((ismissing.(x).==0)) ) =>:nmis2)

			[( (a1.nmis2[i]==a1.mid2[i]) && (a1.rr2[i]=a1.rr2[i]/a1.Tnewsh2[i] *a1.remsh2[i]) ) for i in eachindex(a1.erev)]

			[( ( (a1.nmis2[i]==a1.mid2[i]-1) & (a1.Tnewsh2[i]<a1.remsh2[i]) )
			&& (a1.rr2[i]=a1.rr2[i]) ) for i in eachindex(a1.erev) if (ismissing(a1.rr2[i]==0))]

			[( ( (a1.nmis2[i]==a1.mid2[i]-1) & (a1.Tnewsh2[i]<a1.remsh2[i]) )
			&& (a1.rr2[i]=a1.remsh2[i]-a1.Tnewsh2[i])  ) for i in eachindex(a1.erev) if (ismissing(a1.rr2[i]==1))]


			#we merge the data
			a1=a1[:,[:ctry,:nace4,:rr2]]
			dg2=leftjoin(dg2,a1,on=[:ctry,:nace4])
			dg2[:,:nace2].=""
			[dg2.nace2[i]=SubString(dg2.nace4[i],1:2) for i in eachindex(dg2.nace4)]
			dg2[:,:nace3].=""
			[dg2.nace3[i]=SubString(dg2.nace4[i],1:3) for i in eachindex(dg2.nace4)]

			[( ((dg2.rsh42[i]==-1) & (ismissing(dg2.rr2[i])==0)) && (dg2.rsh42[i]=dg2.rr2[i])) for i in eachindex(dg2.rr2)]

			dg2=missi2(dg2,"rsh42",-1) ; dg2=dg2[:,Not(:rr2)]
			end
			end
			return dg2
	end


dg1=solveprob1(2017,dg1) ; display(sum(dg1.mis))
dg1=solveprob1(2016,dg1) ; display(sum(dg1.mis))
dg1=solveprob1(2015,dg1) ; display(sum(dg1.mis))
dg1=solveprob1(2014,dg1) ; display(sum(dg1.mis))


dg1u=dg1[(dg1.mis2.!=0),:] ; dg1s=dg1[(dg1.mis2.==0),:]




###########################################################################################################
############################################################################################################
###############				 	3) WE USE RELATIVE SHARES FROM ORBIS					#############################
############################################################################################################
#########################################################################################################

############################################################################################################
######################															############################
###############				 	DATA FROM ORBIS					#############################
#################																##############################
############################################################################################################


		function cleanrev(dg,dn,var) #this is for data from 2018, dn is the name of the country, var is the name of the variable (wage, rev, etc)
		  df=DataFrame(nace=dg[:,3],id=dg[:,4],xx1=dg[:,6],xx2=dg[:,5],xx3=dg[:,7],ctry=dn) #we use 2018

		  	df[:,:nace4].=string.(df.nace)

			mapcols(col -> replace!(col, "n.a."=> "-1"), df)
			mapcols(col -> replace!(col, ""=> "-1"), df)
			df.xx1=coalesce.(df.xx1, "-1") ; 			df.xx2=coalesce.(df.xx2, "-1") ; 			df.xx3=coalesce.(df.xx2, "-1")
			df.xx1=tryparse.(Float64,string.(df.xx1)); 	df.xx2=tryparse.(Float64,string.(df.xx2)) ;  df.xx3=tryparse.(Float64,string.(df.xx3))

			###we now create different DFs to identify at least one value of xxenues
			df=df[(df.xx1 .>0) .| (df.xx2 .>0 .| (df.xx3 .>0)), :]
			df[:,:xx].=df.xx1
			[(if df.xx1[i]<=0 df.xx[i]=df.xx2[i] end) for i in eachindex(df.xx)]
			[(if df.xx[i]<=0 df.xx[i]=df.xx3[i] end) for i in eachindex(df.xx)]
			[(if df.xx[i]<=0 df.xx[i]=-1 end) for i in eachindex(df.xx)]
			df=unique(df[:,[:ctry,:id,:nace4,:xx]])

			df[:,:nace2].="" ; df[:,:nace3].=""
			[df.nace2[i]=SubString(df.nace4[i],1:2) for i in eachindex(df.nace4)]
			[df.nace3[i]=SubString(df.nace4[i],1:3) for i in eachindex(df.nace4)]
			df=df[df.xx.>0,:]

			df=unique(df)
			df=rename(df, :xx => Symbol("$var"))

			return df
		  end

dfs=[DataFrame(CSV.File("$(homedir())\\Desktop\\ORBIS\\allcountries\\$(value)_2019_rev_manuf.csv"))  for (key,value) in enumerate(dn.nctry)] # to create a vector with dfs
[dfs[i]=cleanrev(dfs[i],dn[i,:cctry],Symbol("orev")) for i in eachindex(dn.ind)]
odf=copy(dfs) ; odf=vcat(odf...)

		odf=transform(DataFrames.groupby(odf,[:nace2,:ctry]),:orev => sum => :Orev2)
		odf=transform(DataFrames.groupby(odf,[:nace3,:ctry]),:orev => sum => :Orev3)
		odf=transform(DataFrames.groupby(odf,[:nace4,:ctry]),:orev => sum => :Orev4)


odf=unique(odf[:,contains.(names(odf),[r"ctry|Or|nace|sh"])])
odf[:,:year].=yr


odf4=copy(odf)
sort!(odf4,[:ctry,:nace4])

dg1u=leftjoin(dg1u,odf4[:,[:ctry,:nace4,:Orev4]],on=[:ctry,:nace4])
[( (ismissing(dg1u.Orev4[i])==1) && (dg1u.Orev4[i]=0) ) for i in eachindex(dg1u.ctry)]


dg1u=transform(DataFrames.groupby(dg1u,[:ctry,:nace2]), [:Orev4,:rsh42] => ( (x,z) -> sum(x[i]*(z[i]==-1) for i in eachindex(x)) ) => :Orev2)
dg1u[:,:osh42].=dg1u.Orev4./dg1u.Orev2 .* dg1u.remsh2 .* (dg1u.rsh42.==-1)

[( (dg1u.rsh42[i]==-1) && (dg1u.rsh42[i]=dg1u.osh42[i]) ) for i in eachindex(dg1u.ctry)]


###########################################################################################################
############################################################################################################
###############				 	4) WE MERGE ALL DATA					#############################
############################################################################################################
#########################################################################################################

#dg0 was originally solved, dg1 was having at least one missing at nace2 level
#dg1u is what we couldn't solve through previous years of eurostat

vect=[:ctry,:nace2,:nace4,:rsh42]
df42=vcat(dg0[:,vect],dg1s[:,vect],dg1u[:,vect])
sort!(df42,[:ctry,:nace4])
replace!(df42.rsh42, NaN=>0)
#CSV.write("$(homedir())\\Desktop\\ORBIS\\eurostat\\turnover_calc\\newcode02\\nace42.csv",df42)

```

```julia:code02
#hideall
include("$(homedir())\\Desktop\\ORBIS\\eurostat\\turnover_calc\\newcode02\\page\\_assets\\scripts\\page01.jl");

```

\end{section}

\begin{section}{title="To GitHub"}\label{sec3}
\end{section}

