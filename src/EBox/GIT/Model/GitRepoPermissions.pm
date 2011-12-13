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

package EBox::GIT::Model::GitRepoPermissions;


use strict;
use warnings;

use EBox::Exceptions::DataExists;
use EBox::Gettext;
use EBox::Global;
use EBox::View::Customizer;

use base 'EBox::Model::DataTable';

sub new
{
      my ($class, %opts) = @_;
      my $self = $class->SUPER::new(%opts);
      bless ( $self, $class);

      return $self;
}

sub populateUser
{
    my $userMod = EBox::Global->modInstance('users');
    my @users = map (
            {
            value => $_->{uid},
            printableValue => $_->{user}
            }, @{$userMod->usersList()}
            );
    return \@users;
}

sub populateGroup
{
    my $userMod = EBox::Global->modInstance('users');
    my @groups = map (
                {
                    value => $_->{gid},
                    printableValue => $_->{account}
                }, $userMod->groups()
            );
    return \@groups;
}


sub populatePermissions
{
    return [
            {
                value => 'readOnly',
                printableValue => __('Read only')
            },
            {
                value => 'readWrite',
                printableValue => __('Read and write')
            },
            {
                value => 'readWriteRewind',
                printableValue => __('Read, write and rewind')
            },
           ];
}

# Method: _table
#
# Overrides:
#
#     <EBox::Model::DataTable::_table>
#
sub _table
{
    my ($self) = @_;

    my @tableDesc =
      (
       new EBox::Types::Union(
                               fieldName     => 'user_group',
                               printableName => __('User/Group'),
                               subtypes =>
                                [
                                    new EBox::Types::Select(
                                        fieldName => 'user',
                                        printableName => __('User'),
                                        populate => \&populateUser,
                                        editable => 1,
                                        disableCache => 1),
                                    new EBox::Types::Select(
                                        fieldName => 'group',
                                        printableName => __('Group'),
                                        populate => \&populateGroup,
                                        editable => 1,
                                        disableCache => 1),
                                ],
                                unique => 1,
                                filter => \&filterUserGroupPrintableValue,
                              ),

       new EBox::Types::Select(
                               fieldName     => 'permissions',
                               printableName => __('Permissions'),
                               populate => \&populatePermissions,
                               editable => 1,
                               help => '', #FIXME
                              ),
      );

    my $dataTable = {
                     tableName          => 'GitRepoPermissions',
                     printableTableName => __('Access Control'),
                     modelDomain        => 'GIT',
                     menuNamespace      => 'GIT/View/GitRepoPermissions',
                     defaultActions     => [ 'add', 'del', 'editField', 'changeView' ],
                     tableDescription   => \@tableDesc,
                     class              => 'dataTable',
                     help               => '',
                     printableRowName   => __('ACL'),
                     insertPosition     => 'back',
                    };

      return $dataTable;
}

sub filterUserGroupPrintableValue
{
    my ($element) = @_;
    my $selectedType = $element->selectedType();
    my $value = $element->value();
    if ($selectedType eq 'user') {
        return $value . __(' (user))')
    } elsif ($selectedType eq 'group') {
        return $value . __(' (group))')
    }

    return $value;
}

1;
