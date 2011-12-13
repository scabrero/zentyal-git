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

package EBox::GitLdapUser;

use strict;
use warnings;

use File::Slurp;
use EBox::Gettext;
use EBox::Global;
use EBox::Config;
use EBox::UsersAndGroups;
use EBox::Model::ModelManager;

use base qw(EBox::LdapUserBase);

use constant GITDIR   => '/var/lib/gitolite/gitolite-admin/.git';
use constant REPODIR  => '/var/lib/gitolite/gitolite-admin';
use constant KEYDIR   => '/var/lib/gitolite/gitolite-admin/keydir';

sub new
{
    my $class = shift;
    my $self  = {};
    $self->{ldap} = EBox::Ldap->instance();
    $self->{git} = EBox::Global->modInstance('git');
    bless($self, $class);
    return $self;
}

sub _userAddOns
{
    my ($self, $username) = @_;

    return unless ($self->{git}->configured());

    my $active = 'no';
    $active = 'yes' if ($self->hasAccount($username));

    my $key = undef;
    $key = $self->getKey($username);

    my $args = {
        'username' => $username,
        'active'   => $active,
        'key' => $key,
        'service' => $self->{git}->isEnabled(),
    };

    return { path => '/git/git.mas', params => $args };
}

sub getKey
{
    my ($self, $username) = @_;

    my $keyPath = KEYDIR . "/$username.pub";
    my $key = undef;
    if( -e $keyPath ) {
        $key = read_file($keyPath);
    }
    return $key;
}

sub hasAccount
{
    my ($self, $username) = @_;

    my $keyPath = KEYDIR . "/$username.pub";
    if( -e $keyPath ) {
        return 1;
    } else {
        return 0;
    }
}

sub setHasAccount
{
    my ($self, $username, $active, $key) = @_;

    my $keyPath = KEYDIR . "/$username.pub";
    if ($active) {
        my $tmpKeyPath = EBox::Config::tmp() . "/$username.pub";
        write_file( $tmpKeyPath, $key );

        # If the key exists check if it has changed
        my $setupKey = 1;
        if (-e $keyPath) {
            my $currentKey = read_file( $keyPath );
            if ($currentKey eq $key) {
                $setupKey = 0;
            }
        }

        if ($setupKey) {
            EBox::Sudo::root("mv $tmpKeyPath $keyPath");
            EBox::Sudo::root("chown gitolite:gitolite $keyPath");
            EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . " add keydir/$username.pub", 'gitolite' );
            EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . " commit -q -m 'Add user $username'", 'gitolite' );
            EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . ' push', 'gitolite' );
        }
    } else {
        if (-e $keyPath) {
            EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . " rm keydir/$username.pub", 'gitolite' );
            EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . " commit -q -m 'Remove user $username'", 'gitolite' );
            EBox::Sudo::sudo('git --git-dir ' . GITDIR . ' --work-tree ' . REPODIR . ' push', 'gitolite' );
        }
    }

    return 0;
}

1;
