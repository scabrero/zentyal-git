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

package EBox::GIT;

use strict;
use warnings;

use EBox::Global;
use EBox::Gettext;
use EBox::GitLdapUser;
use EBox::UsersAndGroups;
use EBox::Module::Service;

use base qw(EBox::Module::Service EBox::Model::ModelProvider
            EBox::LdapModule);

use constant CONFFILE => '/var/lib/gitolite/gitolite-admin/conf/gitolite.conf';
use constant GITDIR   => '/var/lib/gitolite/gitolite-admin/.git';
use constant REPODIR  => '/var/lib/gitolite/gitolite-admin';

# Method: _create
#
# Overrides:
#
#       <Ebox::Module::_create>
#
sub _create
{
    my $class = shift;
    my $self = $class->SUPER::_create(name => 'git',
            printableName => __('GIT SCM'),
            @_);
    bless ($self, $class);
    return $self;
}

# Method: modelClasses
#
# Overrides:
#
#       <EBox::Model::ModelProvider::modelClasses>
#
sub modelClasses
{
    return [
        'EBox::GIT::Model::GitRepos',
        'EBox::GIT::Model::GitRepoPermissions',
    ];
}

# Method: actions
#
#	Override EBox::Module::Service::actions
#
sub actions
{
    return [
    {
        'action' => __('Create gitolite user ssh keys'),
        'reason' => __('Zentyal will create a pair of ssh keys for gitolite user' ),
        'module' => 'git'
    },
    {
        'action' => __('Setup gitolite'),
        'reason' => __('Zentyal will setup gitolite using the created keys'),
        'module' => 'git'
    },
    {
        'action' => __('Clone gitolite-admin repository'),
        'reason' => __('Zentyal will clone the gitolite-admin repository in the gitolite ' .
                       'user home' ),
        'module' => 'git'
    },
    ];
}

# Method: _setConf
#
#       Overrides base method.
#
sub _setConf
{
    my ($self) = @_;

    my @array = ();
    my $repos  = $self->repos();
    push (@array, 'repos' => $repos);

    my $groups = $self->groups();
    push (@array, 'groups' => $groups);

    $self->writeConfFile(CONFFILE,
                 "git/gitolite.conf.mas",
                 \@array);

    EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . ' add conf/gitolite.conf', 'gitolite' );
    EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . ' commit -q -m "Update config"', 'gitolite' );
    EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . ' push', 'gitolite' );
}

# Method: menu
#
# Overrides:
#
#       <EBox::Module::menu>
#
sub menu
{
    my ($self, $root) = @_;
    $root->add(new EBox::Menu::Item('url' => 'GIT/View/GitRepos',
                                    'text' => $self->printableName(),
                                    'separator' => 'Development',
                                    'order' => 999 ));
}

# Method: _ldapModImplementation
#
#      All modules using any of the functions in LdapUserBase.pm
#      should override this method to return the implementation
#      of that interface.
#
# Returns:
#
#       An object implementing EBox::LdapUserBase
#
sub _ldapModImplementation
{
    return new EBox::GitLdapUser();
}

# Method: repos
#
#   It returns the repositories
#
# Returns:
#
#   Array ref containing hash ref with:
#
#   repo    - repository's name
#   comment - repository's comment
#   readOnly - string containing users and groups with read-only permissions
#   readWrite - string containing users and groups with read and write
#               permissions
#   readWriteRewind  - string containing users and groups with read, write and rewind permissions

sub repos
{
    my ($self) = @_;

    my $repos = $self->model('GitRepos');
    my @repos;

    for my $id (@{$repos->enabledRows()}) {
        my @readOnly;
        my @readWrite;
        my @readWriteRewind;
        my $repoConf;

        my $row = $repos->row($id);
        $repoConf->{'repo'} = $row->elementByName('repo')->value();
        $repoConf->{'description'} = $row->elementByName('description')->value();

        # Get ACL
        for my $subId (@{$row->subModel('access')->ids()}) {
            my $subRow = $row->subModel('access')->row($subId);
            my $userType = $subRow->elementByName('user_group');
            my $preCar = '';
            if ($userType->selectedType() eq 'group') {
                $preCar = '@';
            }
            my $user =  $preCar . $userType->printableValue();

            my $permissions = $subRow->elementByName('permissions');
            if ($permissions->value() eq 'readOnly') {
                push (@readOnly, $user);
            } elsif ($permissions->value() eq 'readWrite') {
                push (@readWrite, $user);
            } elsif ($permissions->value() eq 'readWriteRewind') {
                push (@readWriteRewind, $user)
            }
        }

        $repoConf->{'readOnly'} = join (' ', @readOnly);
        $repoConf->{'readWrite'} = join (' ', @readWrite);
        $repoConf->{'readWriteRewind'} = join (' ', @readWriteRewind);

        push (@repos, $repoConf);
    }

    return \@repos;
}

sub groups
{
    my $usersModule = EBox::Global->modInstance('users');
    my @groupsList = $usersModule->groups();
    my @groupsConf = ();
    foreach my $group (@groupsList) {
        my $groupConf;
        $groupConf->{'group'} = $group->{'account'};
        my $members = $usersModule->usersInGroup($group->{'account'});
        $groupConf->{'members'} = $members;
        push(@groupsConf, $groupConf);
    }
    return \@groupsConf;
}

1;
