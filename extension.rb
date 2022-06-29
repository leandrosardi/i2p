BlackStack::Extensions::add ({
    # descriptive name and descriptor
    :name => 'I2P',
    :description => 'Invoicing and Payments Processing (I2P) is a Ruby gem and MySaaS extension to setup offers in your website, create invoices, and process payments automatically.',

    # setup the url of the repository for installation and updates
    :repo_url => 'https://github.com/leandrosardi/i2p',
    :repo_branch => 'master',

    # define version with format <mayor>.<minor>.<revision>
    :version => '0.0.1',

    # define the name of the author
    :author => 'leandrosardi',

    # what is the section to add this extension in either the top-bar, the footer, the dashboard.
    :apps_section => 'Software Services',
    # show this extension as a service in the top bar?
    :show_in_top_bar => false,
    # show this extension as a service in the footer?
    :show_in_footer => false,
    # show this extension as a service in the dashboard?
    :show_in_dashboard => false,

    # add some screens of this extension to the account settings of your SaaS.
    :setting_screens => [
        # add a link in section `Billing & Finances` of the `/settings` screen, with a caption `Invoices`, and linking to the screen `/settings/invoices`. The source code of the screen `/settings/invoices` is copied from the file `/vews/invoices.erb` in the extension's folder. 
        { :section => 'Billing & Finances', :label => 'Invoices', :screen => :invoices },
        { :section => 'Billing & Finances', :label => 'PayPal Subscriptions', :screen => :subscriptions },
        { :section => 'Billing & Finances', :label => 'Transactions', :screen => :transactions },
    ],

=begin
    # what are the screens to add in the leftbar
    :leftbar_icons => [
        # add an icon with the label "dashboard`, with the icon `icon-dashboard`, and poiting to the scren `helpdesk/dashboard`. 
        { :label => 'search', :icon => :'icon-search', :screen => :search, },
        # add an icon with the label "tickets`, with the icon `icon-envelope`, and poiting to the scren `helpdesk/tickets`. 
        { :label => 'exports', :icon => :'icon-download-cloud', :screen => :exports, },
    ],
 
    # add a folder to the storage from where user can download the exports.
    :storage_folders => [
        { :name => 'exports.leads', },
    ],
=end
})