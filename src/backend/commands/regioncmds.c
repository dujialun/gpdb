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

#include "commands/regioncmds.h"

/*
 * CREATE REGION
 */
void
CreateRegion(CreateRegionStmt *stmt)
{
	ereport(ERROR,
			(errcode(ERRCODE_INSUFFICIENT_PRIVILEGE),
			 errmsg("must be superuser to create resource groups")));
}
