# Copyright (C) 2011 Samuel Cabrero Alaman
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License, version 2, as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package EBox::GIT::Model::GitRepos;

use EBox::Global;
use EBox::Gettext;
use EBox::Validate qw(:all);
use EBox::Model::Row;
use EBox::Exceptions::External;
use EBox::Types::Text;

use strict;
use warnings;

use base 'EBox::Model::DataTable';

sub new
{
    my $class = shift;
    my %parms = @_;

    my $self = $class->SUPER::new(@_);
    bless($self, $class);

    return $self;
}

sub _table
{
    my @tableHead =
        (
         new EBox::Types::Text(
             'fieldName' => 'repo',
             'printableName' => __('Name'),
             'size' => '12',
             'editable' => 1,
             ),
         new EBox::Types::Text(
             'fieldName' => 'description',
             'printableName' => __('Description'),
             'size'=> '50',
             'editable' => '1',
             'optional' => '1',
             ),
         new EBox::Types::HasMany(
             fieldName     => 'access',
             printableName => __('Access control'),
             'foreignModel' => 'GitRepoPermissions',
             'view' => '/GIT/View/GitRepoPermissions'
             ),
         );

    my $dataTable =
    {
        'tableName' => 'GitRepos',
        'printableTableName' => __('Repositories'),
        'modelDomain' => 'GIT',
        'defaultActions' => ['add', 'del', 'editField', 'changeView'],
        'tableDescription' => \@tableHead,
        'printableRowName' => __('Repository'),
        'sortedBy' => 'repo',
        'help' => '',
    };

    return $dataTable;
}

1;
