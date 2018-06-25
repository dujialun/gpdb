/*-------------------------------------------------------------------------
 *
 * getaddrinfo.c
 *	  Support getaddrinfo() on platforms that don't have it.
 *
 * We also supply getnameinfo() here, assuming that the platform will have
 * it if and only if it has getaddrinfo().	If this proves false on some
 * platform, we'll need to split this file and provide a separate configure
 * test for getnameinfo().
 *
 * Windows may or may not have these routines, so we handle Windows specially
 * by dynamically checking for their existence.  If they already exist, we
 * use the Windows native routines, but if not, we use our own.
 *
 *
 * Copyright (c) 2003-2010, PostgreSQL Global Development Group
 *
 * IDENTIFICATION
 *	  $PostgreSQL: pgsql/src/port/getaddrinfo.c,v 1.30 2010/01/02 16:58:13 momjian Exp $
 *
 *-------------------------------------------------------------------------
 */

/* This is intended to be used in both frontend and backend, so use c.h */
#include "c.h"

#include <sys/socket.h>
#include <netdb.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#include "getaddrinfo.h"
#include "libpq/pqcomm.h"		/* needed for struct sockaddr_storage */


#ifdef WIN32
/*
 * The native routines may or may not exist on the Windows platform we are on,
 * so we dynamically look up the routines, and call them via function pointers.
 * Here we need to declare what the function pointers look like
 */
typedef int (__stdcall * getaddrinfo_ptr_t) (const char *nodename,
														 const char *servname,
											   const struct addrinfo * hints,
													 struct addrinfo ** res);

typedef void (__stdcall * freeaddrinfo_ptr_t) (struct addrinfo * ai);

typedef int (__stdcall * getnameinfo_ptr_t) (const struct sockaddr * sa,
														 int salen,
													 char *host, int hostlen,
													 char *serv, int servlen,
														 int flags);

/* static pointers to the native routines, so we only do the lookup once. */
static getaddrinfo_ptr_t getaddrinfo_ptr = NULL;
static freeaddrinfo_ptr_t freeaddrinfo_ptr = NULL;
static getnameinfo_ptr_t getnameinfo_ptr = NULL;


static bool
haveNativeWindowsIPv6routines(void)
{
	void	   *hLibrary = NULL;
	static bool alreadyLookedForIpv6routines = false;

	if (alreadyLookedForIpv6routines)
		return (getaddrinfo_ptr != NULL);

	/*
	 * For Windows XP and Windows 2003 (and longhorn/vista), the IPv6 routines
	 * are present in the WinSock 2 library (ws2_32.dll). Try that first
	 */

	hLibrary = LoadLibraryA("ws2_32");

	if (hLibrary == NULL || GetProcAddress(hLibrary, "getaddrinfo") == NULL)
	{
		/*
		 * Well, ws2_32 doesn't exist, or more likely doesn't have
		 * getaddrinfo.
		 */
		if (hLibrary != NULL)
			FreeLibrary(hLibrary);

		/*
		 * In Windows 2000, there was only the IPv6 Technology Preview look in
		 * the IPv6 WinSock library (wship6.dll).
		 */

		hLibrary = LoadLibraryA("wship6");
	}

	/* If hLibrary is null, we couldn't find a dll with functions */
	if (hLibrary != NULL)
	{
		/* We found a dll, so now get the addresses of the routines */

		getaddrinfo_ptr = (getaddrinfo_ptr_t) GetProcAddress(hLibrary,
															 "getaddrinfo");
		freeaddrinfo_ptr = (freeaddrinfo_ptr_t) GetProcAddress(hLibrary,
															 "freeaddrinfo");
		getnameinfo_ptr = (getnameinfo_ptr_t) GetProcAddress(hLibrary,
															 "getnameinfo");

		/*
		 * If any one of the routines is missing, let's play it safe and
		 * ignore them all
		 */
		if (getaddrinfo_ptr == NULL ||
			freeaddrinfo_ptr == NULL ||
			getnameinfo_ptr == NULL)
		{
			FreeLibrary(hLibrary);
			hLibrary = NULL;
			getaddrinfo_ptr = NULL;
			freeaddrinfo_ptr = NULL;
			getnameinfo_ptr = NULL;
		}
	}

	alreadyLookedForIpv6routines = true;
	return (getaddrinfo_ptr != NULL);
}
#endif


/*
 * get address info for ipv4 sockets.
 *
 *	Bugs:	- only one addrinfo is set even though hintp is NULL or
 *		  ai_socktype is 0
 *		- AI_CANONNAME is not supported.
 *		- servname can only be a number, not text.
 */
int
getaddrinfo(const char *node, const char *service,
			const struct addrinfo * hintp,
			struct addrinfo ** res)
{
	struct addrinfo *ai;
	struct sockaddr_in sin,
			   *psin;
	struct addrinfo hints;

#ifdef WIN32

	/*
	 * If Windows has native IPv6 support, use the native Windows routine.
	 * Otherwise, fall through and use our own code.
	 */
	if (haveNativeWindowsIPv6routines())
		return (*getaddrinfo_ptr) (node, service, hintp, res);
#endif

	if (hintp == NULL)
	{
		memset(&hints, 0, sizeof(hints));
		hints.ai_family = AF_INET;
		hints.ai_socktype = SOCK_STREAM;
	}
	else
		memcpy(&hints, hintp, sizeof(hints));

	if (hints.ai_family != AF_INET && hints.ai_family != AF_UNSPEC)
		return EAI_FAMILY;

	if (hints.ai_socktype == 0)
		hints.ai_socktype = SOCK_STREAM;

	if (!node && !service)
		return EAI_NONAME;

	memset(&sin, 0, sizeof(sin));

	sin.sin_family = AF_INET;

	if (node)
	{
		if (node[0] == '\0')
			sin.sin_addr.s_addr = htonl(INADDR_ANY);
		else if (hints.ai_flags & AI_NUMERICHOST)
		{
			if (!inet_aton(node, &sin.sin_addr))
				return EAI_FAIL;
		}
		else
		{
			struct hostent *hp;

#ifdef FRONTEND
			struct hostent hpstr;
			char		buf[BUFSIZ];
			int			herrno = 0;

			pqGethostbyname(node, &hpstr, buf, sizeof(buf),
							&hp, &herrno);
#else
			hp = gethostbyname(node);
#endif
			if (hp == NULL)
			{
				switch (h_errno)
				{
					case HOST_NOT_FOUND:
					case NO_DATA:
						if (Gp_role == GP_ROLE_DISPATCH)
							FtsNotifyProber();
						return EAI_NONAME;
					case TRY_AGAIN:
						return EAI_AGAIN;
					case NO_RECOVERY:
					default:
						return EAI_FAIL;
				}
			}
			if (hp->h_addrtype != AF_INET)
				return EAI_FAIL;

			memcpy(&(sin.sin_addr), hp->h_addr, hp->h_length);
		}
	}
	else
	{
		if (hints.ai_flags & AI_PASSIVE)
			sin.sin_addr.s_addr = htonl(INADDR_ANY);
		else
			sin.sin_addr.s_addr = htonl(INADDR_LOOPBACK);
	}

	if (service)
		sin.sin_port = htons((unsigned short) atoi(service));

#ifdef HAVE_STRUCT_SOCKADDR_STORAGE_SS_LEN
	sin.sin_len = sizeof(sin);
#endif

	ai = malloc(sizeof(*ai));
	if (!ai)
		return EAI_MEMORY;

	psin = malloc(sizeof(*psin));
	if (!psin)
	{
		free(ai);
		return EAI_MEMORY;
	}

	memcpy(psin, &sin, sizeof(*psin));

	ai->ai_flags = 0;
	ai->ai_family = AF_INET;
	ai->ai_socktype = hints.ai_socktype;
	ai->ai_protocol = hints.ai_protocol;
	ai->ai_addrlen = sizeof(*psin);
	ai->ai_addr = (struct sockaddr *) psin;
	ai->ai_canonname = NULL;
	ai->ai_next = NULL;

	*res = ai;

	return 0;
}


void
freeaddrinfo(struct addrinfo * res)
{
	if (res)
	{
#ifdef WIN32

		/*
		 * If Windows has native IPv6 support, use the native Windows routine.
		 * Otherwise, fall through and use our own code.
		 */
		if (haveNativeWindowsIPv6routines())
		{
			(*freeaddrinfo_ptr) (res);
			return;
		}
#endif

		if (res->ai_addr)
			free(res->ai_addr);
		free(res);
	}
}


const char *
gai_strerror(int errcode)
{
#ifdef HAVE_HSTRERROR
	int			hcode;

	switch (errcode)
	{
		case EAI_NONAME:
			hcode = HOST_NOT_FOUND;
			break;
		case EAI_AGAIN:
			hcode = TRY_AGAIN;
			break;
		case EAI_FAIL:
		default:
			hcode = NO_RECOVERY;
			break;
	}

	return hstrerror(hcode);
#else							/* !HAVE_HSTRERROR */

	switch (errcode)
	{
		case EAI_NONAME:
			return "Unknown host";
		case EAI_AGAIN:
			return "Host name lookup failure";
			/* Errors below are probably WIN32 only */
#ifdef EAI_BADFLAGS
		case EAI_BADFLAGS:
			return "Invalid argument";
#endif
#ifdef EAI_FAMILY
		case EAI_FAMILY:
			return "Address family not supported";
#endif
#ifdef EAI_MEMORY
		case EAI_MEMORY:
			return "Not enough memory";
#endif
#ifdef EAI_NODATA
#ifndef WIN32_ONLY_COMPILER		/* MSVC complains because another case has the
								 * same value */
		case EAI_NODATA:
			return "No host data of that type was found";
#endif
#endif
#ifdef EAI_SERVICE
		case EAI_SERVICE:
			return "Class type not found";
#endif
#ifdef EAI_SOCKTYPE
		case EAI_SOCKTYPE:
			return "Socket type not supported";
#endif
		default:
			return "Unknown server error";
	}
#endif   /* HAVE_HSTRERROR */
}

/*
 * Convert an ipv4 address to a hostname.
 *
 * Bugs:	- Only supports NI_NUMERICHOST and NI_NUMERICSERV
 *		  It will never resolv a hostname.
 *		- No IPv6 support.
 */
int
getnameinfo(const struct sockaddr * sa, int salen,
			char *node, int nodelen,
			char *service, int servicelen, int flags)
{
#ifdef WIN32

	/*
	 * If Windows has native IPv6 support, use the native Windows routine.
	 * Otherwise, fall through and use our own code.
	 */
	if (haveNativeWindowsIPv6routines())
		return (*getnameinfo_ptr) (sa, salen, node, nodelen,
								   service, servicelen, flags);
#endif

	/* Invalid arguments. */
	if (sa == NULL || (node == NULL && service == NULL))
		return EAI_FAIL;

	/* We don't support those. */
	if ((node && !(flags & NI_NUMERICHOST))
		|| (service && !(flags & NI_NUMERICSERV)))
		return EAI_FAIL;

#ifdef	HAVE_IPV6
	if (sa->sa_family == AF_INET6)
		return EAI_FAMILY;
#endif

	if (node)
	{
		int			ret = -1;

		if (sa->sa_family == AF_INET)
		{
			char	   *p;

			p = inet_ntoa(((struct sockaddr_in *) sa)->sin_addr);
			ret = snprintf(node, nodelen, "%s", p);
		}
		if (ret == -1 || ret > nodelen)
			return EAI_MEMORY;
	}

	if (service)
	{
		int			ret = -1;

		if (sa->sa_family == AF_INET)
		{
			ret = snprintf(service, servicelen, "%d",
						   ntohs(((struct sockaddr_in *) sa)->sin_port));
		}
		if (ret == -1 || ret > servicelen)
			return EAI_MEMORY;
	}

	return 0;
}
