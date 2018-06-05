/*-------------------------------------------------------------------------
 *
 * pg_region.h
 *	  definition of the system "region" relation (pg_region).
 *
 *
 *
 * NOTES
 *	  the genbki.sh script reads this file and generates .bki
 *	  information from the DATA() statements.
 *
 *-------------------------------------------------------------------------
 */
#ifndef PG_REGION_H
#define PG_REGION_H

#include "catalog/genbki.h"

// TODO
#define RegionRelationId 8721

CATALOG(pg_region,8721) BKI_SHARED_RELATION
{
	NameData	regname;		/* name of region */
	
	int2       segments[1];   /* TODO: add comment*/

} FormData_pg_region;

/* no foreign keys */

/* ----------------
 *	Form_pg_region corresponds to a pointer to a tuple with
 *	the format of pg_region relation.
 * ----------------
 */
typedef FormData_pg_region *Form_pg_region;

/* ----------------
 *	compiler constants for pg_region
 * ----------------
 */
#define Natts_pg_region				2
#define Anum_pg_region_regname		1
#define Anum_pg_region_segments		2

#endif   /* PG_REGION_H */
