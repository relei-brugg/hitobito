# encoding: UTF-8
require 'spec_helper'
describe Subscriber::UserController do

  before { sign_in(person) }

  let(:group) { groups(:top_group) }
  let(:person) { people(:top_leader) }
  let(:list) { Fabricate(:mailing_list, group: group, subscribable: true) }

  context "POST create" do
    
    context "as any user" do
      let(:person) { Fabricate(Group::BottomLayer::Leader.name.to_sym, group: groups(:bottom_layer_one)).person }
      
      it "can create new subscription" do
        expect { post :create, group_id: group.id, mailing_list_id: list.id }.to change(Subscription, :count).by(1)
      end
      
      it "cannot create new subscription if mailing list not subscribable" do
        list.update_column(:subscribable, false)
        expect { post :create, group_id: group.id, mailing_list_id: list.id }.not_to change(Subscription, :count)
      end
    end
    
    context "as admin user"  do
      it "creates new subscription" do
        expect { post :create, group_id: group.id, mailing_list_id: list.id }.to change(Subscription, :count).by(1)
      end
  
      it "creates new subscription only once" do
        Fabricate(:subscription, mailing_list: list, subscriber: person)
  
        expect { post :create, group_id: group.id, mailing_list_id: list.id }.not_to change(Subscription, :count)
      end
  
      it "updates excluded subscription" do
        subscription = Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: true)
        subscription.should be_excluded
        expect { post :create, group_id: group.id, mailing_list_id: list.id }.not_to change(Subscription, :count)
  
        subscription.reload.should_not be_excluded
      end
  
      after do
        flash[:notice].should eq "Du wurdest dem Abo erfolgreich hinzugefügt"
        should redirect_to group_mailing_list_path(group_id: list.group.id, id: list.id)
      end
    end
  end


  context "POST destroy" do
    it "creates exclusion when no direct subscription exists" do
      Fabricate(:subscription, mailing_list: list, subscriber: groups(:top_layer), excluded: false, role_types: [Group::TopGroup::Leader.sti_name])
      expect { post :destroy, group_id: group.id, mailing_list_id: list.id }.to change { Subscription.count }.by(1)

      person.subscriptions.last.should be_excluded
    end
    
    it "handle multiple direct and indirect subscription" do
      Fabricate(:subscription, mailing_list: list, subscriber: groups(:top_layer), excluded: false, role_types: [Group::TopGroup::Leader.sti_name])
      Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: false)
      expect { post :destroy, group_id: group.id, mailing_list_id: list.id }.not_to change { Subscription.count }

      person.subscriptions.last.should be_excluded
    end
    
    it "destroys direct subscription" do
      Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: false)
      expect { post :destroy, group_id: group.id, mailing_list_id: list.id }.to change { Subscription.count }.by(-1)

      person.subscriptions.should be_empty
    end
    
    it "does not create exclusion twice" do
      Fabricate(:subscription, mailing_list: list, subscriber: person, excluded: true)

      expect { post :destroy, group_id: group.id, mailing_list_id: list.id }.not_to change { Subscription.count }.by(1)
      person.subscriptions.last.should be_excluded
    end

    after do
      flash[:notice].should eq "Du wurdest erfolgreich vom Abo entfernt"
      should redirect_to group_mailing_list_path(group_id: list.group.id, id: list.id)
    end
  end

end
