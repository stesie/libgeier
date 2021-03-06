/*
 * Copyright (C) 2006,2007  Stefan Siegl <stesie@brokenpipe.de>, Germany
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */

#ifndef GEIER_PKCS7_KEYING
#define GEIER_PKCS7_KEYING

/* Mozilla header files */
#include <nss.h>
#include <secpkcs7.h>
#include <pk11func.h>


PK11SymKey *geier_pkcs7_encryption_key(geier_context *ctx, PK11SlotInfo* slot);

#endif

