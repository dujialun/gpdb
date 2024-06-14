"""
Copyright (c) 2004-Present Pivotal Software, Inc.

This program and the accompanying materials are made available under
the terms of the under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
"""

from mpp.models import SQLTestCase

'''
Class for AOCO_compression sanity
'''

class AOCOCompression(SQLTestCase):
    """
    @description: sanity for aoco_compression
    @gucs gp_create_table_random_default_distribution=off
    @product_version gpdb: [4.3-]
    """

    sql_dir = 'sanity/'
    ans_dir = 'expected/sanity/'
    out_dir = 'output/'