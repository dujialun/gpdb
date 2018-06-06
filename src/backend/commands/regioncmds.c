/*-------------------------------------------------------------------------
 *
 * regioncmds.c
 *	  Commands for manipulating region.
 *
 * Portions Copyright (c) 2006-2017, Greenplum inc.
 * Portions Copyright (c) 2012-Present Pivotal Software, Inc.
 *
 * IDENTIFICATION
 *    src/backend/commands/region.c
 *
 *-------------------------------------------------------------------------
 */
#include "postgres.h"

#include "funcapi.h"
#include "libpq-fe.h"
#include "access/genam.h"
#include "access/heapam.h"
#include "access/xact.h"
#include "catalog/heap.h"
#include "catalog/oid_dispatch.h"
#include "catalog/pg_region.h"
#include "catalog/pg_authid.h"
#include "cdb/cdbdisp_query.h"
#include "cdb/cdbdispatchresult.h"
#include "cdb/cdbvars.h"
#include "commands/comment.h"
#include "commands/defrem.h"
#include "commands/regioncmds.h"
#include "miscadmin.h"
#include "utils/builtins.h"
#include "utils/datetime.h"
#include "utils/fmgroids.h"
#include "utils/resowner.h"
#include "utils/syscache.h"
#include "utils/faultinjector.h"

/*
 * CREATE REGION
 */
void
CreateRegion(CreateRegionStmt *stmt)
{
	Relation	pg_region_rel;
	TupleDesc	pg_region_dsc;
	ScanKeyData scankey;
	SysScanDesc sscan;
	HeapTuple	tuple;
	Oid			regionid;
	Datum		new_record[Natts_pg_region];
	bool		new_record_nulls[Natts_pg_region];
	/* Permission check - only superuser can create regions. */
	if (!superuser())
		ereport(ERROR,
				(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
				 errmsg("must be superuser to create regions")));

	
	pg_region_rel = heap_open(RegionRelationId, AccessExclusiveLock);

	/*
	 * Build a tuple to insert
	 */
	MemSet(new_record, 0, sizeof(new_record));
	MemSet(new_record_nulls, false, sizeof(new_record_nulls));

	new_record_nulls[1] = true;

	new_record[Anum_pg_region_regname - 1] =
		DirectFunctionCall1(namein, CStringGetDatum(stmt->name));
	
	pg_region_dsc = RelationGetDescr(pg_region_rel);
	tuple = heap_form_tuple(pg_region_dsc, new_record, new_record_nulls);

	/*
	 * Insert new record in the pg_resgroup table
	 */
	regionid = simple_heap_insert(pg_region_rel, tuple);
	CatalogUpdateIndexes(pg_region_rel, tuple);

	if (Gp_role == GP_ROLE_DISPATCH)
	{
		CdbDispatchUtilityStatement((Node *) stmt,
									DF_CANCEL_ON_ERROR|
									DF_WITH_SNAPSHOT|
									DF_NEED_TWO_PHASE,
									GetAssignedOidsForDispatch(),
									NULL);
		MetaTrackAddObject(RegionRelationId,
						   regionid,
						   GetUserId(), /* not ownerid */
						   "CREATE", "REGION");
	}
	heap_close(pg_region_rel, NoLock);
}
