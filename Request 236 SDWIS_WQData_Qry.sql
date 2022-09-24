--QUERY 1: List all WQ results for these 4 PS codes
	--CA3710008_001_001
	--CA3710008_013_001
	--CA3710008_003_003
	--CA3710008_013_003
With S1 as (
SELECT DISTINCT
--PS CODE INFORMATION
--S1.[District/LPA] as RegAgency,
TINWSYS.NUMBER0 as SystemID,
Concat(substring(TINWSYS.NUMBER0,1,9),'_',(TINWSF.ST_ASGN_IDENT_CD),'_',substring(TSASMPPT.IDENTIFICATION_CD,1,3)) as PSCode,
TINWSF.TYPE_CODE as FacilityType,
TINWSF.ACTIVITY_STATUS_CD as FacilityStatus,

--SAMPLE INFORMATION
Format(TSASAMPL.COLLLECTION_END_DT, 'MM-dd-yyyy') as SampleDate,
Case
	When TSASAMPL.COLLCTN_END_TIME IS NULL
	then 'NULL'
	else Convert(varchar,TSASAMPL.COLLCTN_END_TIME, 108)
	end as SampleTime,		
TSASAMPL.TYPE_CODE as SampleType,
ltrim(rtrim(TSALAB.LAB_ID_NUMBER)) as ELAPCert,
TINLGENT.NAME as LabName,							
TSAANLYT.CODE as AnalyteCode,
TSAANLYT.NAME as AnalyteName,

--RESULT INFORMATION
TSASAR.CONCENTRATION_MSR As Result,
format(TSASAR.D_INITIAL_TS,'yyyy-MM-dd') as ResultCreationTimestamp,
TSASAR.D_INITIAL_USERID as ResultCreatedBy,
format(TSASAR.D_LAST_UPDT_TS, 'yyyy-MM-dd') as ResultUpdateTimestamp,
TSASAR.D_USERID_CODE as ResultUpdatedBy,
TSASAR.DATA_QTY_RSN_CD as ResultDataQualityFlag,

--Sampling Point Information
TSASMPPT.DESCRIPTION_TEXT as SamplingPointDescription,
TSASMPPT.ACTIVITY_RSN_TXT as SamplingPointActivityReason,
TSASMPPT.IDENTIFICATION_CD as SamplingPointID,
TSASMPPT.D_INITIAL_USERID as SamplingPointCreatedBy,
TSASMPPT.D_INITIAL_TS as SamplingPointCreationTimestamp,
TSASMPPT.D_USERID_CODE as SamplingPointUpdatedBy,
TSASMPPT.D_LAST_UPDT_TS as SamplingPointUpdateTimestamp

--Into #S1 --Drop Table #S1
FROM SDWIS..TINWSYS 

INNER JOIN SDWIS..TINWSF ON (TINWSF.TINWSYS_IS_NUMBER = TINWSYS.TINWSYS_IS_NUMBER)
INNER JOIN SDWIS..TSASMPPT ON (TSASMPPT.TINWSF0IS_NUMBER = TINWSF.TINWSF_IS_NUMBER)	
INNER JOIN SDWIS..TSASAMPL ON (TSASAMPL.TSASMPPT_IS_NUMBER = TSASMPPT.TSASMPPT_IS_NUMBER) -- removes 003-003 PS Code
INNER JOIN SDWIS..TSASAR ON (TSASAR.TSASAMPL_IS_NUMBER = TSASAMPL.TSASAMPL_IS_NUMBER)	
INNER JOIN SDWIS..TSAANLYT ON (TSASAR.TSAANLYT_ST_CODE = TSAANLYT.TSAANLYT_ST_CODE) 
	AND (TSASAR.TSAANLYT_IS_NUMBER = TSAANLYT.TSAANLYT_IS_NUMBER)
INNER JOIN SDWIS..TSALAB ON (TSASAMPL.TSALAB_IS_NUMBER = TSALAB.TSALAB_IS_NUMBER)
INNER JOIN SDWIS..TSALLEA ON (TSALAB.TSALAB_IS_NUMBER = TSALLEA.TSALAB0IS_NUMBER)
INNER JOIN SDWIS..TINLGENT	ON (TSALLEA.TINLGENT0IS_NUMBER = TINLGENT.TINLGENT_IS_NUMBER)

INNER JOIN		
   (Select
	TINLGENT.Name as 'District/LPA',
	TINWSYS.TINWSYS_IS_NUMBER
	from TINWSYS
	INNER JOIN TINRAA on TINWSYS.TINWSYS_IS_NUMBER = TINRAA.TINWSYS_IS_NUMBER
		and TINRAA.ACTIVE_IND_CD = 'A'
	INNER JOIN TINLGENT on TINLGENT.TINLGENT_IS_NUMBER = TINRAA.TINLGENT_IS_NUMBER
		where TINLGENT.name like 'lpa%' 
		or TINLGENT.name like 'district%'
	) as s1
	on (s1.TINWSYS_IS_NUMBER = TINWSYS.TINWSYS_IS_NUMBER)

WHERE 
TINWSYS.NUMBER0 = 'CA3710008'
and TSASMPPT.IDENTIFICATION_CD IN ('001', '003')
)
--Select Distinct PScode, SamplingPointID from S1 order by SamplingPointID ASC

--TEMP TABLE Selects
--Select Distinct PSCode, SamplingPointID from #S1 order by SamplingPointID ASC
--Select * from #S1 order by SamplingPointID ASC

--QUERY 2: Count # results by PS Code
, AddPartition As (
Select S1.*,
--Partition Clause
Count(*) OVER (
	Partition By PSCode) as ResultCount
FROM S1
)
Select Distinct
--AddPartition.*,
AddPartition.PSCode,
AddPartition.ResultCount
From AddPartition
Order by PSCode ASC
--973 results for PS Code CA3710008-001-001
--41 results for PS Code CA3710008-013-001
--41 results for PS Code CA3710009-013-003

--QUERY 3--lists duplicate PS codes for system CA3710008
SELECT
TINLGENT.NAME as Regulating_Agency,
TINWSYS.NUMBER0 as System_ID,
'CA'+ RIGHT(RTRIM(TINWSYS.NUMBER0),7)+ '_' + TINWSF.ST_ASGN_IDENT_CD+ '_' + TSASMPPT.IDENTIFICATION_CD As [New PS Code],
TINWSF.ST_ASGN_IDENT_CD as FacilityID,
TSASMPPT.IDENTIFICATION_CD as SamplingPointID,
TSASMPPT.DESCRIPTION_TEXT AS [Sample Point Name]

FROM SDWIS.DBO.TINWSYS

INNER JOIN SDWIS.DBO.TINRAA
ON TINWSYS.TINWSYS_IS_NUMBER = TINRAA.TINWSYS_IS_NUMBER
AND TINRAA.ACTIVE_IND_CD = 'A'

INNER JOIN SDWIS.DBO.TINLGENT
ON TINRAA.TINLGENT_IS_NUMBER = TINLGENT.TINLGENT_IS_NUMBER
AND (TINLGENT.NAME Like 'district%' Or TINLGENT.NAME Like '%lpa%')

INNER JOIN SDWIS.DBO.TINWSF
ON TINWSYS.TINWSYS_IS_NUMBER = TINWSF.TINWSYS_IS_NUMBER
--AND TINWSF.ACTIVITY_STATUS_CD = 'A'

INNER JOIN SDWIS.DBO.TSASMPPT
ON TINWSF.TINWSF_IS_NUMBER = TSASMPPT.TINWSF0IS_NUMBER
--AND TSASMPPT.ACTIVITY_STATUS_CD ='A'

WHERE 
(TINLGENT.NAME LIKE '%District%' Or TINLGENT.NAME LIKE '%LPA%')
and TINWSYS.NUMBER0 = 'CA3710008'
and TSASMPPT.IDENTIFICATION_CD IN ('001', '003')
Order by SamplingPointID ASC


/*Does PS Code CA3710008-003-003 have any data in SDWIS?
--GUI reveals no results; save screen-capture
--Query 1 reveals no results when we filter for just PS Code CA3710008-003-003









--Select Count(*) from S1 --Returns 1054 rows on 9/23/2022 on SQL-3 in 8 s
--Select Count(PK) from S1
--Returns 1054 distinct PKs; all results are unique because S1 contains 1054 records

--Query 2: Extract unique fields from TSASMPPT
--SELECT DISTINCT
--    c.name 'Column Name',
--    t.Name 'Data type',
--    c.max_length 'Max Length',
--    c.is_nullable,
--    ISNULL(i.is_primary_key, 0) 'Primary Key'
--FROM    
--    sys.columns c
--INNER JOIN 
--    sys.types t ON c.user_type_id = t.user_type_id
--LEFT OUTER JOIN 
--    sys.index_columns ic ON ic.object_id = c.object_id AND ic.column_id = c.column_id
--LEFT OUTER JOIN 
--    sys.indexes i ON ic.object_id = i.object_id AND ic.index_id = i.index_id
--WHERE
--  c.object_id = OBJECT_ID('TSASMPPT')

-- Select
-- DESCRIPTION_TEXT,
-- ACTIVITY_RSN_TXT,
-- IDENTIFICATION_CD as 'SamplingPointID',
-- D_INITIAL_USERID as 'CreatedBy',
-- D_INITIAL_TS as 'CreationTimestamp',
-- D_USERID_CODE as 'UpdatedBy',
-- D_LAST_UPDT_TS as 'UpdateTimestamp'
--from SDWIS..TSASMPPT
-- Where ACTIVITY_RSN_TXT LIKE '%XML Sampling%'