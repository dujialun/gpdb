/*-------------------------------------------------------------------------
 *
 * regioncmds.h
 *	  Commands for manipulating region.
 *
 * Portions Copyright (c) 2006-2017, Greenplum inc.
 * Portions Copyright (c) 2012-Present Pivotal Software, Inc.
 *
 * IDENTIFICATION
 * 		src/include/commands/regioncmds.h
 *
 *-------------------------------------------------------------------------
 */
#ifndef REGIONCMDS_H
#define REGIONCMDS_H

#include "nodes/parsenodes.h"

extern void CreateRegion(CreateRegionStmt *stmt);

#endif   /* REGIONCMDS_H */
